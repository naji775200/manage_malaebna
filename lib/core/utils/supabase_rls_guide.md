# Supabase Row Level Security (RLS) Setup Guide

## Overview

This guide explains how to set up Row Level Security (RLS) policies for Supabase storage buckets and database tables to allow proper image uploads and entity image record creation.

## 1. Setting Up Storage Bucket Policies

### Step 1: Access the Supabase Dashboard

1. Log in to your Supabase dashboard at https://app.supabase.io
2. Select your project
3. Navigate to "Storage" in the left sidebar

### Step 2: Configure Storage Bucket Policies

For each bucket (`images/stadium`, `images/fields`, `images/owners`):

1. Click on the bucket name
2. Select the "Policies" tab
3. Click "Add Policy"

### Step 3: Create Policies for Authenticated Users

#### For Read Access (everyone can view images):

```sql
-- Policy name: Allow public read access
CREATE POLICY "Allow public read access"
ON storage.objects
FOR SELECT USING (
  bucket_id IN ('images/stadium', 'images/fields', 'images/owners')
);
```

#### For Upload Access (only authenticated users):

```sql
-- Policy name: Allow authenticated uploads
CREATE POLICY "Allow authenticated uploads"
ON storage.objects
FOR INSERT TO authenticated USING (
  bucket_id IN ('images/stadium', 'images/fields', 'images/owners')
);
```

#### For Update/Delete Access (only authenticated users who own the resource):

```sql
-- Policy name: Allow owners to update and delete
CREATE POLICY "Allow owners to update and delete"
ON storage.objects
FOR UPDATE USING (
  auth.uid() = owner
) WITH CHECK (
  auth.uid() = owner
);

CREATE POLICY "Allow owners to delete"
ON storage.objects
FOR DELETE USING (
  auth.uid() = owner
);
```

## 2. Setting Up Database Table Policies

### Step 1: Access Database Settings

1. Navigate to "Database" in the left sidebar
2. Select "Tables" to see your tables

### Step 2: Configure RLS for the `entity_images` Table

1. Find the `entity_images` table
2. Click the three dots next to it and select "Edit Policies"

### Step 3: Create Policies for the `entity_images` Table

#### For Read Access (public):

```sql
-- Policy name: Allow public read access
CREATE POLICY "Allow public read access"
ON public.entity_images
FOR SELECT USING (true);
```

#### For Insert Access (authenticated users):

```sql
-- Policy name: Allow authenticated users to insert
CREATE POLICY "Allow authenticated users to insert"
ON public.entity_images
FOR INSERT TO authenticated WITH CHECK (true);
```

#### For Update/Delete Access (authenticated users who own the resource):

```sql
-- Policy name: Allow authenticated users to update their records
CREATE POLICY "Allow authenticated users to update their records"
ON public.entity_images
FOR UPDATE TO authenticated USING (
  auth.uid() IN (
    SELECT user_id FROM stadiums WHERE id = entity_id AND entity_type = 'stadium'
  )
) WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM stadiums WHERE id = entity_id AND entity_type = 'stadium'
  )
);

-- Policy name: Allow authenticated users to delete their records
CREATE POLICY "Allow authenticated users to delete their records"
ON public.entity_images
FOR DELETE TO authenticated USING (
  auth.uid() IN (
    SELECT user_id FROM stadiums WHERE id = entity_id AND entity_type = 'stadium'
  )
);
```

## 3. Testing Your RLS Policies

After setting up these policies:

1. Make sure your user is properly authenticated in the app
2. Try uploading images from the app
3. Check the Supabase storage bucket to verify images are being uploaded
4. Check the `entity_images` table to verify records are being created

If you're still experiencing issues, you can temporarily disable RLS for testing:

1. Navigate to the table or bucket settings
2. Toggle "Enable RLS" to off
3. Test your functionality
4. Remember to re-enable RLS with proper policies for production

## 4. Common Issues and Solutions

1. **Authentication Issues**: Make sure your session token is valid and not expired
2. **Path Issues**: Verify the bucket paths match exactly what's in your code
3. **Permission Issues**: Check if your policies have syntax errors or logical issues
4. **Owner Field**: Ensure the owner field is properly set when uploading files

## 5. Secure Development Practices

For production apps:

- Never disable RLS in production
- Always implement proper authentication flows
- Use the most restrictive policies possible
- Consider adding rate limiting for uploads
- Validate file types and sizes before uploading
