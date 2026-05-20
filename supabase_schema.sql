-- Sting Study Assistant (SSA) Supabase Database Schema
-- Paste this script in the Supabase SQL Editor and run it to set up your backend.

-- 1. Create PUBLIC USERS Table
CREATE TABLE public.users (
    id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
    full_name TEXT,
    email TEXT UNIQUE NOT NULL,
    academic_level TEXT DEFAULT 'Undergraduate',
    profile_image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) for public.users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public.users
CREATE POLICY "Allow public read access to profiles" 
ON public.users FOR SELECT 
USING (true);

CREATE POLICY "Allow individual users to update their own profile" 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

-- Trigger to automatically create a public profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, email, academic_level)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Student User'),
        new.email,
        COALESCE(new.raw_user_meta_data->>'academic_level', 'Computer Science')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. Create NOTES Table
CREATE TABLE public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for public.notes
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public.notes
CREATE POLICY "Allow individual users to select their own notes" 
ON public.notes FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to insert their own notes" 
ON public.notes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual users to update their own notes" 
ON public.notes FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to delete their own notes" 
ON public.notes FOR DELETE 
USING (auth.uid() = user_id);


-- 3. Create QUIZZES Table
CREATE TABLE public.quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    quiz_title TEXT NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for public.quizzes
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public.quizzes
CREATE POLICY "Allow individual users to select their own quizzes" 
ON public.quizzes FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to insert their own quizzes" 
ON public.quizzes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual users to delete their own quizzes" 
ON public.quizzes FOR DELETE 
USING (auth.uid() = user_id);


-- 4. Create STUDY TASKS Table
CREATE TABLE public.study_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    task_title TEXT NOT NULL,
    task_description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    completed BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for public.study_tasks
ALTER TABLE public.study_tasks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public.study_tasks
CREATE POLICY "Allow individual users to select their own study tasks" 
ON public.study_tasks FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to insert their own study tasks" 
ON public.study_tasks FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual users to update their own study tasks" 
ON public.study_tasks FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to delete their own study tasks" 
ON public.study_tasks FOR DELETE 
USING (auth.uid() = user_id);


-- 5. Create AI CHATS Table
CREATE TABLE public.ai_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for public.ai_chats
ALTER TABLE public.ai_chats ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public.ai_chats
CREATE POLICY "Allow individual users to select their own ai chats" 
ON public.ai_chats FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual users to insert their own ai chats" 
ON public.ai_chats FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual users to delete their own ai chats" 
ON public.ai_chats FOR DELETE 
USING (auth.uid() = user_id);


-- 6. SETUP STORAGE BUCKETS
-- Run this block if you want to create public buckets named 'pdf_notes' and 'profile_images' programmatically, 
-- or create them using the Supabase Dashboard UI.
INSERT INTO storage.buckets (id, name, public) VALUES ('pdf_notes', 'pdf_notes', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profile_images', 'profile_images', true) ON CONFLICT DO NOTHING;

-- RLS Storage Policies
CREATE POLICY "Allow public read access on pdf_notes bucket" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'pdf_notes');

CREATE POLICY "Allow authenticated users to insert objects in pdf_notes bucket" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'pdf_notes' AND auth.role() = 'authenticated');

CREATE POLICY "Allow public read access on profile_images bucket" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'profile_images');

CREATE POLICY "Allow authenticated users to insert objects in profile_images bucket" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'profile_images' AND auth.role() = 'authenticated');
