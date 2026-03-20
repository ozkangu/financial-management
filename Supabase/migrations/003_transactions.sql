-- Migration 003: Transactions table

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'TRY',
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    payment_method TEXT,
    visibility_scope TEXT NOT NULL CHECK (visibility_scope IN ('personal', 'shared')) DEFAULT 'personal',
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    recurrence_interval TEXT CHECK (recurrence_interval IN ('weekly', 'monthly', 'yearly')),
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_transactions_workspace_date ON public.transactions(workspace_id, date DESC);
CREATE INDEX idx_transactions_workspace_type ON public.transactions(workspace_id, type);
CREATE INDEX idx_transactions_user ON public.transactions(user_id);
CREATE INDEX idx_transactions_category ON public.transactions(category_id);

-- Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Transactions policies: workspace members can access transactions
CREATE POLICY "Users can read transactions in their workspaces"
    ON public.transactions FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Users can insert transactions in their workspaces"
    ON public.transactions FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'member')
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can update own transactions"
    ON public.transactions FOR UPDATE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces
            WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own transactions"
    ON public.transactions FOR DELETE
    USING (
        user_id = auth.uid()
        OR workspace_id IN (
            SELECT id FROM public.workspaces
            WHERE owner_id = auth.uid()
        )
    );

-- Updated_at trigger
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
