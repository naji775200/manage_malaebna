/* 
HOW TO USE THIS FILE:

1. Log in to your Supabase project at https://app.supabase.com
2. Go to the SQL Editor (click on "SQL Editor" in the left sidebar)
3. Create a new query
4. Copy and paste the contents of this file into the editor
5. Run the query to create both functions
6. These functions will be used as fallbacks if the normal insert/upsert operations fail

These functions help ensure stadium and owner data gets properly saved to your Supabase
database even if there are issues with the normal insert process.
*/

-- Supabase SQL functions for fallback insertion
-- Run these in the SQL Editor in your Supabase Dashboard

-- Function for fallback stadium insertion
create or replace function insert_stadium_fallback(
  p_id uuid,
  p_name text,
  p_phone_number text,
  p_address_id uuid default null
) returns integer as $$
declare
  v_count integer;
begin
  -- Check if stadium already exists
  select count(*) into v_count from stadiums where id = p_id;
  
  if v_count > 0 then
    -- Update existing stadium
    update stadiums set
      name = p_name,
      phone_number = p_phone_number,
      updated_at = now()
    where id = p_id;
    return 1;
  else
    -- Insert new stadium
    insert into stadiums (
      id, 
      name, 
      phone_number, 
      status, 
      address_id,
      description,
      bank_number,
      average_review,
      booked_count,
      type,
      created_at,
      updated_at
    ) values (
      p_id,
      p_name,
      p_phone_number,
      'pending',
      p_address_id,
      '',
      '',
      0.0,
      0,
      'standard',
      now(),
      now()
    );
    return 1;
  end if;

exception when others then
  return 0;
end;
$$ language plpgsql security definer;

-- Function for fallback owner insertion
create or replace function insert_owner_fallback(
  p_id uuid,
  p_name text,
  p_phone_number text
) returns integer as $$
declare
  v_count integer;
begin
  -- Check if owner already exists
  select count(*) into v_count from owners where id = p_id;
  
  if v_count > 0 then
    -- Update existing owner
    update owners set
      name = p_name,
      phone_number = p_phone_number,
      updated_at = now()
    where id = p_id;
    return 1;
  else
    -- Insert new owner
    insert into owners (
      id, 
      name, 
      phone_number, 
      status,
      created_at,
      updated_at
    ) values (
      p_id,
      p_name,
      p_phone_number,
      'active',
      now(),
      now()
    );
    return 1;
  end if;

exception when others then
  return 0;
end;
$$ language plpgsql security definer; 