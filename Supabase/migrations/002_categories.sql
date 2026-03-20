-- Migration 002: Categories table with default seed data

CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    color TEXT NOT NULL DEFAULT '#007AFF',
    icon TEXT NOT NULL DEFAULT 'folder.fill',
    monthly_budget DECIMAL(15, 2),
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Categories policies: workspace members can read categories
CREATE POLICY "Users can read categories of their workspaces"
    ON public.categories FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Workspace owners can manage categories"
    ON public.categories FOR INSERT
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Workspace members can update categories"
    ON public.categories FOR UPDATE
    USING (
        workspace_id IN (
            SELECT workspace_id FROM public.workspace_members
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

CREATE POLICY "Workspace owners can delete categories"
    ON public.categories FOR DELETE
    USING (
        workspace_id IN (
            SELECT id FROM public.workspaces
            WHERE owner_id = auth.uid()
        )
    );

-- Function to seed default categories for a new workspace
CREATE OR REPLACE FUNCTION public.seed_default_categories(ws_id UUID)
RETURNS VOID AS $$
DECLARE
    -- Expense parent category IDs
    konut_id UUID;
    ulasim_id UUID;
    gida_id UUID;
    yatirim_gelir_id UUID;
BEGIN
    -- === EXPENSE CATEGORIES ===

    -- Konut (parent)
    INSERT INTO public.categories (id, workspace_id, name, type, color, icon, is_default)
    VALUES (gen_random_uuid(), ws_id, 'Konut', 'expense', '#FF6B6B', 'house.fill', true)
    RETURNING id INTO konut_id;

    -- Konut subcategories
    INSERT INTO public.categories (workspace_id, name, type, parent_id, color, icon, is_default) VALUES
        (ws_id, 'Kira', 'expense', konut_id, '#FF6B6B', 'key.fill', true),
        (ws_id, 'Aidat', 'expense', konut_id, '#FF6B6B', 'building.2.fill', true),
        (ws_id, 'Elektrik', 'expense', konut_id, '#FF6B6B', 'bolt.fill', true),
        (ws_id, 'Su', 'expense', konut_id, '#FF6B6B', 'drop.fill', true),
        (ws_id, 'Doğalgaz', 'expense', konut_id, '#FF6B6B', 'flame.fill', true),
        (ws_id, 'İnternet', 'expense', konut_id, '#FF6B6B', 'wifi', true);

    -- Ulaşım (parent)
    INSERT INTO public.categories (id, workspace_id, name, type, color, icon, is_default)
    VALUES (gen_random_uuid(), ws_id, 'Ulaşım', 'expense', '#4ECDC4', 'car.fill', true)
    RETURNING id INTO ulasim_id;

    INSERT INTO public.categories (workspace_id, name, type, parent_id, color, icon, is_default) VALUES
        (ws_id, 'Yakıt', 'expense', ulasim_id, '#4ECDC4', 'fuelpump.fill', true),
        (ws_id, 'Toplu Taşıma', 'expense', ulasim_id, '#4ECDC4', 'bus.fill', true),
        (ws_id, 'Araç Bakım', 'expense', ulasim_id, '#4ECDC4', 'wrench.fill', true);

    -- Gıda (parent)
    INSERT INTO public.categories (id, workspace_id, name, type, color, icon, is_default)
    VALUES (gen_random_uuid(), ws_id, 'Gıda', 'expense', '#FFD93D', 'cart.fill', true)
    RETURNING id INTO gida_id;

    INSERT INTO public.categories (workspace_id, name, type, parent_id, color, icon, is_default) VALUES
        (ws_id, 'Market', 'expense', gida_id, '#FFD93D', 'basket.fill', true),
        (ws_id, 'Restoran/Yeme-İçme', 'expense', gida_id, '#FFD93D', 'fork.knife', true);

    -- Other expense categories (no subcategories)
    INSERT INTO public.categories (workspace_id, name, type, color, icon, is_default) VALUES
        (ws_id, 'Sağlık', 'expense', '#FF8C94', 'heart.fill', true),
        (ws_id, 'Eğitim', 'expense', '#A8D8EA', 'book.fill', true),
        (ws_id, 'Eğlence', 'expense', '#C3AED6', 'gamecontroller.fill', true),
        (ws_id, 'Giyim', 'expense', '#FFB6B9', 'tshirt.fill', true),
        (ws_id, 'Kişisel Bakım', 'expense', '#FFDAC1', 'comb.fill', true),
        (ws_id, 'Çocuk', 'expense', '#B5EAD7', 'figure.and.child.holdinghands', true),
        (ws_id, 'Abonelikler', 'expense', '#957DAD', 'repeat', true),
        (ws_id, 'Diğer', 'expense', '#95E1D3', 'ellipsis.circle.fill', true);

    -- === INCOME CATEGORIES ===

    INSERT INTO public.categories (workspace_id, name, type, color, icon, is_default) VALUES
        (ws_id, 'Maaş', 'income', '#2ECC71', 'briefcase.fill', true),
        (ws_id, 'Serbest Çalışma', 'income', '#27AE60', 'laptopcomputer', true),
        (ws_id, 'Kira Geliri', 'income', '#1ABC9C', 'house.fill', true);

    -- Yatırım Geliri (parent)
    INSERT INTO public.categories (id, workspace_id, name, type, color, icon, is_default)
    VALUES (gen_random_uuid(), ws_id, 'Yatırım Geliri', 'income', '#3498DB', 'chart.line.uptrend.xyaxis', true)
    RETURNING id INTO yatirim_gelir_id;

    INSERT INTO public.categories (workspace_id, name, type, parent_id, color, icon, is_default) VALUES
        (ws_id, 'Temettü', 'income', yatirim_gelir_id, '#3498DB', 'banknote.fill', true),
        (ws_id, 'Faiz', 'income', yatirim_gelir_id, '#3498DB', 'percent', true),
        (ws_id, 'Kar Payı', 'income', yatirim_gelir_id, '#3498DB', 'chart.pie.fill', true);

    INSERT INTO public.categories (workspace_id, name, type, color, icon, is_default) VALUES
        (ws_id, 'Satış', 'income', '#E67E22', 'tag.fill', true),
        (ws_id, 'Hediye', 'income', '#9B59B6', 'gift.fill', true),
        (ws_id, 'Diğer', 'income', '#7F8C8D', 'ellipsis.circle.fill', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
