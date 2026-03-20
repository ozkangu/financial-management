-- Migration 005: Assets, Liabilities, and Net Worth Snapshots tables

CREATE TABLE IF NOT EXISTS public.assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'bank_account', 'cash', 'investment', 'real_estate',
        'vehicle', 'receivable', 'other'
    )),
    value DECIMAL(15, 2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'TRY',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.liabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'credit_card', 'personal_loan', 'mortgage',
        'auto_loan', 'personal_debt', 'other'
    )),
    total_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    remaining_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    interest_rate DECIMAL(5, 2),
    monthly_payment DECIMAL(15, 2),
    currency TEXT NOT NULL DEFAULT 'TRY',
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.net_worth_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_assets DECIMAL(15, 2) NOT NULL DEFAULT 0,
    total_liabilities DECIMAL(15, 2) NOT NULL DEFAULT 0,
    net_worth DECIMAL(15, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(workspace_id, date)
);

-- Indexes
CREATE INDEX idx_assets_workspace ON public.assets(workspace_id);
CREATE INDEX idx_liabilities_workspace ON public.liabilities(workspace_id);
CREATE INDEX idx_net_worth_snapshots_workspace_date ON public.net_worth_snapshots(workspace_id, date DESC);

-- Enable RLS
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.liabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.net_worth_snapshots ENABLE ROW LEVEL SECURITY;

-- Assets policies
CREATE POLICY "Users can read assets in their workspaces"
    ON public.assets FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert assets"
    ON public.assets FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'member')
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can update own assets"
    ON public.assets FOR UPDATE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own assets"
    ON public.assets FOR DELETE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

-- Liabilities policies
CREATE POLICY "Users can read liabilities in their workspaces"
    ON public.liabilities FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert liabilities"
    ON public.liabilities FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'member')
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can update own liabilities"
    ON public.liabilities FOR UPDATE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own liabilities"
    ON public.liabilities FOR DELETE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

-- Net worth snapshots policies
CREATE POLICY "Users can read snapshots of their workspaces"
    ON public.net_worth_snapshots FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert snapshots"
    ON public.net_worth_snapshots FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Updated_at triggers
CREATE TRIGGER update_assets_updated_at
    BEFORE UPDATE ON public.assets
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_liabilities_updated_at
    BEFORE UPDATE ON public.liabilities
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
