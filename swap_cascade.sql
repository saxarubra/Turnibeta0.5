-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_swap_cascade ON shift_swaps_v2;
DROP FUNCTION IF EXISTS handle_swap_cascade();

-- Create the function to handle swap cascading
CREATE OR REPLACE FUNCTION handle_swap_cascade()
RETURNS TRIGGER AS $$
DECLARE
    processed_ids INTEGER[] := ARRAY[]::INTEGER[];
    current_swap RECORD;
    next_swap RECORD;
BEGIN
    -- Only proceed if this is an accepted swap
    IF NEW.status = 'accepted' THEN
        -- Initialize with the current swap
        current_swap := NEW;
        
        -- Process the chain of swaps
        WHILE current_swap IS NOT NULL LOOP
            -- Add current swap to processed list
            processed_ids := array_append(processed_ids, current_swap.id);
            
            -- Find the next swap in the chain
            SELECT * INTO next_swap
            FROM shift_swaps_v2
            WHERE shift_id = current_swap.requested_shift_id
            AND status = 'pending'
            AND id != ALL(processed_ids)
            ORDER BY created_at ASC
            LIMIT 1;
            
            -- If we found a next swap, update it
            IF next_swap IS NOT NULL THEN
                UPDATE shift_swaps_v2
                SET status = 'accepted',
                    updated_at = NOW()
                WHERE id = next_swap.id;
                
                -- Move to next swap in chain
                current_swap := next_swap;
            ELSE
                -- No more swaps in chain
                current_swap := NULL;
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER on_swap_cascade
    AFTER UPDATE ON shift_swaps_v2
    FOR EACH ROW
    EXECUTE FUNCTION handle_swap_cascade(); 