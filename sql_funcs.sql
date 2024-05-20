-- FUNCTION: public.generate_ticket(character varying, uuid, uuid, uuid, character varying, uuid, uuid, uuid)

-- DROP FUNCTION IF EXISTS public.generate_ticket(character varying, uuid, uuid, uuid, character varying, uuid, uuid, uuid);

CREATE OR REPLACE FUNCTION public.generate_ticket(
	p_branch_acronym character varying,
	p_branch_id uuid,
	p_service_id uuid,
	p_customer_id uuid,
	p_status character varying,
	p_dispenser_id uuid,
	p_form_id uuid,
	p_submission_id uuid)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    next_queue_position integer;
    new_ticket_id uuid;
    service_estimated_time integer;
    total_pending_tickets integer;
    estimated_time integer;
    result json;
    current_date date := CURRENT_DATE;
    formatted_ticket_number text;
    new_last_ticket_number integer;
    estimated_interval interval;
    service_interval interval;
BEGIN
    -- Calculate the total pending tickets (including the new ticket)
    SELECT COUNT(*) INTO total_pending_tickets
    FROM public.ticket
    WHERE branch_id = p_branch_id
    AND status = 'Pending';

    -- If all tickets are served, reset the queue position to 0
    IF total_pending_tickets = 0 THEN
        UPDATE public.ticket
        SET queue_position = 0
        WHERE branch_id = p_branch_id;
    END IF;

    -- Check if we need to reset the ticket number (new day)
    IF NOT EXISTS (SELECT 1 FROM public.branch_config WHERE branch_id = p_branch_id AND last_ticket_date = current_date) THEN
        -- Reset the ticket number
        new_last_ticket_number := 1;
        INSERT INTO public.branch_config (branch_id, last_ticket_date, last_ticket_number)
        VALUES (p_branch_id, current_date, new_last_ticket_number)
        ON CONFLICT (branch_id) DO UPDATE
        SET last_ticket_date = EXCLUDED.last_ticket_date, last_ticket_number = EXCLUDED.last_ticket_number;
    ELSE
        -- Increment the last ticket number
        SELECT bc.last_ticket_number + 1 INTO new_last_ticket_number
        FROM public.branch_config AS bc
        WHERE bc.branch_id = p_branch_id;

        UPDATE public.branch_config
        SET last_ticket_number = new_last_ticket_number
        WHERE branch_id = p_branch_id;
    END IF;

    -- Get the next queue position for the branch
    SELECT COALESCE(MAX(t.queue_position), 0) + 1 INTO next_queue_position
    FROM public.ticket AS t
    WHERE t.branch_id = p_branch_id;

    -- Get the estimated service time for the given service
    SELECT s.estimated_time_minutes INTO service_estimated_time
    FROM public.service AS s
    WHERE s.service_id = p_service_id;

    -- Calculate the estimated time for the new ticket (including pending tickets)
    estimated_time := (total_pending_tickets + 1) * service_estimated_time;

    -- Convert estimated times to interval
    estimated_interval := (estimated_time || ' minutes')::interval;
    service_interval := (service_estimated_time || ' minutes')::interval;

    -- Format the ticket number with ticket number and queue position
    formatted_ticket_number := p_branch_acronym || lpad(new_last_ticket_number::text, 3, '0') || '-' || next_queue_position;

    -- Insert the ticket into the table with the correct queue position
    INSERT INTO public.ticket (branch_id, service_id, customer_id, token_number, status, queue_position, dispenser_id, form_id,submission_id)
    VALUES (p_branch_id, p_service_id, p_customer_id, formatted_ticket_number, p_status, next_queue_position, p_dispenser_id, p_form_id,p_submission_id)
    RETURNING ticket_id INTO new_ticket_id;

    -- Insert into queue_item table
    INSERT INTO public.queue_item (queue_id, ticket_id, counter_id, "position", waiting_time, expected_service_time)
    VALUES (p_branch_id, new_ticket_id, p_dispenser_id, next_queue_position, estimated_interval, service_interval);

    -- Insert a log entry for the ticket generation
    INSERT INTO public.queue_log (action_type, ticket_id, user_id)
    VALUES ('Generated', new_ticket_id, p_customer_id);

    -- Construct the result JSON object
    result := json_build_object(
        'ticket', formatted_ticket_number,
        'estimated_time', estimated_time,
        'ticket_data', json_build_object(
            'branch_id', p_branch_id,
            'service_id', p_service_id,
            'customer_id', p_customer_id,
            'status', p_status,
            'queue_position', next_queue_position,
            'dispenser_id', p_dispenser_id,
            'form_id', p_form_id,
            'queue_item_id', new_ticket_id
        )
    );

    RETURN result;
END;
$BODY$;

ALTER FUNCTION public.generate_ticket(character varying, uuid, uuid, uuid, character varying, uuid, uuid, uuid)
    OWNER TO bwilliam;


 -- Step 1: Create the trigger function
-- FUNCTION: public.update_ticket_position()

-- DROP FUNCTION IF EXISTS public.update_ticket_position();

CREATE OR REPLACE FUNCTION public.update_ticket_position()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    -- Update the position of the served or closed ticket to 0
    IF NEW.status IN ('Closed', 'Served') THEN
        UPDATE public.ticket
        SET queue_position = 0
        WHERE ticket_id = NEW.ticket_id;

        -- Update the served status in the queue_item table
        UPDATE public.queue_item
        SET served = true
        WHERE ticket_id = NEW.ticket_id;
    END IF;

    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.update_ticket_position()
    OWNER TO bwilliam;


-- Step 2: Create the trigger
CREATE TRIGGER ticket_status_update_trigger
AFTER UPDATE OF status
ON ticket
FOR EACH ROW
WHEN (OLD.status != 'Served' AND NEW.status = 'Served')
EXECUTE FUNCTION update_ticket_position();


CREATE SEQUENCE queue_item_position_seq;