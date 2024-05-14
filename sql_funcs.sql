CREATE OR REPLACE FUNCTION public.generate_ticket(
    p_branch_acronym character varying,
    p_branch_id uuid,
    p_service_id uuid,
    p_customer_id uuid,
    p_status character varying,
    p_dispenser_id uuid,
    p_form_id uuid)
    RETURNS json
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    next_queue_position integer;
    new_ticket_id uuid;
    service_estimated_time integer;
    pending_tickets_count integer;
    average_service_time integer;
    estimated_time integer;
    result json;
BEGIN
    -- Get the next queue position for the branch
    SELECT COALESCE(MAX(queue_position), 0) + 1 INTO next_queue_position
    FROM public.ticket
    WHERE branch_id = p_branch_id;

    -- Update the queue positions of existing tickets if a ticket is served
    IF p_status = 'Served' THEN
        UPDATE public.ticket
        SET queue_position = queue_position - 1
        WHERE branch_id = p_branch_id
        AND queue_position > 0; -- Update all tickets
    END IF;

    -- Get the estimated service time for the given service (from public.service table)
    SELECT public.service.estimated_time_minutes INTO service_estimated_time
    FROM public.service
    WHERE service_id = p_service_id;

    -- Insert the ticket into the table with the correct queue position
    INSERT INTO public.ticket (branch_id, service_id, customer_id, token_number, status, queue_position, dispenser_id, form_id)
    VALUES (p_branch_id, p_service_id, p_customer_id, p_branch_acronym || lpad(next_queue_position::text, 3, '0'), p_status, next_queue_position, p_dispenser_id, p_form_id)
    RETURNING ticket_id INTO new_ticket_id;

    -- Insert a log entry for the ticket generation
    INSERT INTO public.queue_log (action_type, ticket_id, user_id)
    VALUES ('Generated', new_ticket_id, p_customer_id);

    -- Calculate the estimated time based on pending tickets count and average service time
    SELECT COUNT(*) INTO pending_tickets_count
    FROM public.ticket
    WHERE branch_id = p_branch_id
    AND service_id = p_service_id
    AND status = 'Pending';

    average_service_time := service_estimated_time; -- Assuming constant service time per ticket

    estimated_time := pending_tickets_count * average_service_time;

    -- Construct the result JSON object
    result := json_build_object(
        'ticket', p_branch_acronym || lpad(next_queue_position::text, 3, '0'),
        'estimated_time', estimated_time
    );

    RETURN result;

END;
$BODY$;

 -- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION update_ticket_position()
RETURNS TRIGGER AS $$
DECLARE
    original_positions INTEGER[];
BEGIN
    -- Store original positions of tickets in the branch
    original_positions := ARRAY(
        SELECT queue_position
        FROM ticket
        WHERE branch_id = NEW.branch_id
        ORDER BY generated_time
    );

    -- Update the position of the served ticket to 0
    IF NEW.status = 'Served' THEN
        UPDATE ticket
        SET queue_position = 0
        WHERE ticket_id = NEW.ticket_id;
    END IF;

  

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create the trigger
CREATE TRIGGER ticket_status_update_trigger
AFTER UPDATE OF status
ON ticket
FOR EACH ROW
WHEN (OLD.status != 'Served' AND NEW.status = 'Served')
EXECUTE FUNCTION update_ticket_position();
