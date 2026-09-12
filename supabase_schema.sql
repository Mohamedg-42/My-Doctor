-- ====================================================================
-- SCHEMA POSTGRESQL COMPLET POUR MY DOCTOR (SUPABASE / POSTGRESQL 15+)
-- ====================================================================

-- 1. Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Table des utilisateurs (Patients, Médecins, Administrateurs)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'doctor', 'admin')),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    avatar_base64 TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'pending', 'suspended')),
    cmu_number VARCHAR(50),
    birth_date DATE,
    gender VARCHAR(20),
    profession VARCHAR(100),
    commune VARCHAR(100),
    city VARCHAR(100) DEFAULT 'Abidjan',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- Index de recherche rapide
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- 3. Table des Médecins (Profils étendus)
CREATE TABLE IF NOT EXISTS public.doctors (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    specialty VARCHAR(100) NOT NULL DEFAULT 'Généraliste',
    order_number VARCHAR(50) DEFAULT '00000',
    bio TEXT DEFAULT '',
    consultation_price NUMERIC(10, 2) DEFAULT 15000,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    review_count INT DEFAULT 0,
    patient_count INT DEFAULT 0,
    experience_years INT DEFAULT 5,
    is_available BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT TRUE,
    is_online BOOLEAN DEFAULT TRUE,
    address TEXT DEFAULT 'Abidjan, Côte d''Ivoire',
    latitude DOUBLE PRECISION DEFAULT 5.3484,
    longitude DOUBLE PRECISION DEFAULT -4.0107,
    available_days TEXT[] DEFAULT ARRAY['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'],
    available_slots JSONB DEFAULT '{"Lundi": ["09:00", "10:00", "11:00", "14:00", "15:00"], "Mardi": ["09:00", "10:00", "11:00", "14:00", "15:00"], "Mercredi": ["09:00", "10:00", "11:00", "14:00", "15:00"], "Jeudi": ["09:00", "10:00", "11:00", "14:00", "15:00"], "Vendredi": ["09:00", "10:00", "11:00", "14:00", "15:00"]}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherche de médecins
CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON public.doctors(specialty);
CREATE INDEX IF NOT EXISTS idx_doctors_rating ON public.doctors(rating DESC);

-- 4. Table des Demandes de Médecin Traitant
CREATE TABLE IF NOT EXISTS public.treating_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    patient_name VARCHAR(200) NOT NULL,
    doctor_name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_treating_patient ON public.treating_requests(patient_id);
CREATE INDEX IF NOT EXISTS idx_treating_doctor ON public.treating_requests(doctor_id);
CREATE INDEX IF NOT EXISTS idx_treating_status ON public.treating_requests(status);

-- 5. Table des Rendez-vous
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    patient_name VARCHAR(200) NOT NULL,
    doctor_name VARCHAR(200) NOT NULL,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    type VARCHAR(50) DEFAULT 'consultation',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    notes TEXT,
    price NUMERIC(10, 2) DEFAULT 15000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Table des Messages de Chat
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(sender_id, receiver_id, created_at);

-- 7. Activer les notifications en Temps Réel PostgreSQL (Supabase Realtime)
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.doctors;
ALTER PUBLICATION supabase_realtime ADD TABLE public.treating_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- 8. Données de démonstration initiales (Seed Data)
-- Mot de passe haché SHA-256 de 'Admin123!' = a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3 (exemple)
INSERT INTO public.users (id, role, email, phone, password_hash, first_name, last_name, status, city)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'admin', 'admin@allodocteur.ci', '0100000000', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'Admin', 'Système', 'active', 'Abidjan'),
    ('00000000-0000-0000-0000-000000000002', 'doctor', 'dr.koffi@allodocteur.ci', '0500000001', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'Jean-Luc', 'Koffi', 'active', 'Abidjan'),
    ('00000000-0000-0000-0000-000000000003', 'doctor', 'dr.diallo@allodocteur.ci', '0500000002', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'Fatou', 'Diallo', 'active', 'Abidjan'),
    ('00000000-0000-0000-0000-000000000004', 'patient', 'patient.demo@allodocteur.ci', '0700000001', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'Kouamé', 'Yao', 'active', 'Abidjan')
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.doctors (id, specialty, order_number, bio, consultation_price, rating, review_count, patient_count)
VALUES 
    ('00000000-0000-0000-0000-000000000002', 'Cardiologue', '12345', 'Spécialiste en cardiologie interventionnelle au CHU de Treichville.', 25000, 4.9, 42, 120),
    ('00000000-0000-0000-0000-000000000003', 'Pédiatre', '23456', 'Pédiatre passionnée avec plus de 10 ans d''expérience en soins néonataux.', 18000, 4.8, 38, 95)
ON CONFLICT (id) DO NOTHING;
