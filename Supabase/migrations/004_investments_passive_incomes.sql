-- Migration 004: Investments and Passive Incomes tables

CREATE TABLE IF NOT EXISTS public.investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'stock', 'fund_etf', 'gold', 'forex', 'crypto',
        'real_estate', 'deposit', 'retirement', 'bond', 'other'
    )),
    purchase_date DATE,
    unit_cost DECIMAL(15, 4) NOT NULL DEFAULT 0,
    quantity DECIMAL(15, 6) NOT NULL DEFAULT 0,
    current_value DECIMAL(15, 2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'TRY',
    institution TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.passive_incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    investment_id UUID REFERENCES public.investments(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN (
        'dividend', 'interest', 'rent', 'staking', 'coupon', 'other'
    )),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'TRY',
    frequency TEXT NOT NULL CHECK (frequency IN ('monthly', 'quarterly', 'yearly')) DEFAULT 'monthly',
    next_payment_date DATE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_investments_workspace ON public.investments(workspace_id);
CREATE INDEX idx_investments_user ON public.investments(user_id);
CREATE INDEX idx_passive_incomes_workspace ON public.passive_incomes(workspace_id);
CREATE INDEX idx_passive_incomes_investment ON public.passive_incomes(investment_id);

-- Enable RLS
ALTER TABLE public.investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passive_incomes ENABLE ROW LEVEL SECURITY;

-- Investments policies
CREATE POLICY "Users can read investments in their workspaces"
    ON public.investments FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert investments"
    ON public.investments FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'member')
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can update own investments"
    ON public.investments FOR UPDATE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own investments"
    ON public.investments FOR DELETE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

-- Passive incomes policies
CREATE POLICY "Users can read passive incomes in their workspaces"
    ON public.passive_incomes FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert passive incomes"
    ON public.passive_incomes FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'member')
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can update own passive incomes"
    ON public.passive_incomes FOR UPDATE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own passive incomes"
    ON public.passive_incomes FOR DELETE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        )
    );

-- Updated_at triggers
CREATE TRIGGER update_investments_updated_at
    BEFORE UPDATE ON public.investments
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
