toc.dat                                                                                             0000600 0004000 0002000 00000317471 14620670407 0014462 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP                           |            qms    14.10 (Homebrew)    15.0 �    s           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         t           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         u           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         v           1262    84671    qms    DATABASE     e   CREATE DATABASE qms WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';
    DROP DATABASE qms;
                bwilliam    false                     2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                bwilliam    false         w           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   bwilliam    false    4                    1255    86624 S   generate_ticket(character varying, uuid, uuid, uuid, character varying, uuid, uuid)    FUNCTION     k	  CREATE FUNCTION public.generate_ticket(p_branch_acronym character varying, p_branch_id uuid, p_service_id uuid, p_customer_id uuid, p_status character varying, p_dispenser_id uuid, p_form_id uuid) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;
 �   DROP FUNCTION public.generate_ticket(p_branch_acronym character varying, p_branch_id uuid, p_service_id uuid, p_customer_id uuid, p_status character varying, p_dispenser_id uuid, p_form_id uuid);
       public          bwilliam    false    4                    1255    86660    update_ticket_position()    FUNCTION     ]  CREATE FUNCTION public.update_ticket_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

    -- Update the position of the served or closed ticket to 0
    IF NEW.status IN ('Closed', 'Served') THEN
        UPDATE ticket
        SET queue_position = 0
        WHERE ticket_id = NEW.ticket_id;
    END IF;

    RETURN NEW;
END;
$$;
 /   DROP FUNCTION public.update_ticket_position();
       public          bwilliam    false    4         �            1259    84799    active_directory    TABLE     �  CREATE TABLE public.active_directory (
    ad_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    domain_name character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
 $   DROP TABLE public.active_directory;
       public         heap    bwilliam    false    4         �            1259    84767    branch    TABLE       CREATE TABLE public.branch (
    branch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    name character varying(255) NOT NULL,
    portal_code character varying(20),
    closing_type character varying(50),
    closing_time time without time zone,
    default_language character varying(50),
    time_zone character varying(50),
    enable_appointment boolean DEFAULT false,
    smart_ticket boolean DEFAULT false,
    status boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
    DROP TABLE public.branch;
       public         heap    bwilliam    false    4         �            1259    84757    company    TABLE     �  CREATE TABLE public.company (
    company_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    address character varying(255),
    phone character varying(20),
    email character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
    DROP TABLE public.company;
       public         heap    bwilliam    false    4         �            1259    85144    counter    TABLE     A  CREATE TABLE public.counter (
    counter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    name character varying(255) NOT NULL,
    status boolean DEFAULT true NOT NULL,
    service_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
    DROP TABLE public.counter;
       public         heap    bwilliam    false    4                    1259    86122    counter_ticket    TABLE     �   CREATE TABLE public.counter_ticket (
    counter_ticket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    counter_id uuid,
    ticket_id uuid,
    assigned_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    served boolean DEFAULT false
);
 "   DROP TABLE public.counter_ticket;
       public         heap    bwilliam    false    4         �            1259    85455 	   customers    TABLE       CREATE TABLE public.customers (
    customer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    email character varying(255),
    phone_number character varying(20),
    address text,
    city character varying(100),
    state character varying(100),
    country character varying(100),
    postal_code character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.customers;
       public         heap    bwilliam    false    4         �            1259    85785    device_logs    TABLE     �  CREATE TABLE public.device_logs (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_name character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    location character varying(255),
    ip_address character varying(50) NOT NULL,
    last_connection timestamp with time zone,
    connection_status boolean,
    connection_log jsonb[],
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.device_logs;
       public         heap    bwilliam    false    4         �            1259    86004    devices    TABLE     `  CREATE TABLE public.devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    device_name character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    ip_address character varying(50) NOT NULL,
    authentication_code character varying(50) NOT NULL,
    license_key character varying(255),
    validity_starts timestamp without time zone,
    validity_ends timestamp without time zone,
    show_appointment_button boolean DEFAULT false,
    show_authentication_button boolean DEFAULT false,
    show_estimated_waiting_time boolean DEFAULT false,
    show_number_of_waiting_clients boolean DEFAULT false,
    num_services_on_one_ticket integer,
    idle_time_before_returning_to_main_screen integer,
    ticket_layout text,
    special_service text,
    agent_info jsonb,
    is_activated boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    activation_status character varying(50),
    activated_at timestamp with time zone
);
    DROP TABLE public.devices;
       public         heap    bwilliam    false    4         �            1259    84845 	   dispenser    TABLE     �  CREATE TABLE public.dispenser (
    dispenser_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    name character varying(255) NOT NULL,
    language character varying(50),
    show_appointment_button boolean DEFAULT false,
    show_authentication_button boolean DEFAULT false,
    show_estimated_waiting_time boolean DEFAULT false,
    show_number_of_waiting_clients boolean DEFAULT false,
    num_services_on_one_ticket integer,
    idle_time_before_returning_to_main_screen integer,
    ticket_layout text,
    validity_starts timestamp without time zone,
    validity_ends timestamp without time zone,
    special_service text,
    agent_name character varying(255),
    agent_ip character varying(50),
    authentication_key character varying(255),
    status boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
    DROP TABLE public.dispenser;
       public         heap    bwilliam    false    4         �            1259    85757    dispenser_device_templates    TABLE     #  CREATE TABLE public.dispenser_device_templates (
    device_template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 .   DROP TABLE public.dispenser_device_templates;
       public         heap    bwilliam    false    4         �            1259    85742    dispenser_templates    TABLE     '  CREATE TABLE public.dispenser_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    branch_id uuid,
    template_type character varying(50) NOT NULL,
    background_color character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    background_video character varying(500),
    background_image character varying(500),
    assigned_to character varying(50),
    news_scroll text
);
 '   DROP TABLE public.dispenser_templates;
       public         heap    bwilliam    false    4         �            1259    85691    display_device_templates    TABLE     !  CREATE TABLE public.display_device_templates (
    device_template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 ,   DROP TABLE public.display_device_templates;
       public         heap    bwilliam    false    4         �            1259    85668    display_devices    TABLE     �  CREATE TABLE public.display_devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    device_name character varying(255) NOT NULL,
    ip_address character varying(50) NOT NULL,
    authentication_code character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 #   DROP TABLE public.display_devices;
       public         heap    bwilliam    false    4         �            1259    85965    display_templates    TABLE     G  CREATE TABLE public.display_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    background_image bytea,
    background_color character varying(20),
    split_type character varying(20),
    page_style character varying(50),
    name_on_display_screen boolean,
    need_mobile_screen boolean,
    show_skip_call boolean,
    show_waiting_call boolean,
    skip_closed_call boolean,
    display_screen_tune character varying(255),
    show_queue_number character varying(20),
    show_missed_queue_number character varying(20),
    full_screen_option boolean,
    show_disclaimer_message boolean,
    show_missed_queue_with_marquee boolean,
    template_type character varying(50) NOT NULL,
    content_source_type character varying(50),
    content_endpoint character varying(255),
    content_source character varying(255),
    section_division integer,
    content_configuration jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 %   DROP TABLE public.display_templates;
       public         heap    bwilliam    false    4         �            1259    86032    file_uploads    TABLE     �  CREATE TABLE public.file_uploads (
    upload_id uuid DEFAULT gen_random_uuid() NOT NULL,
    folder_name character varying(200),
    folder_location character varying(200),
    file_name character varying(500),
    file_type character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    upload_for character varying(100),
    uploaded_by uuid,
    old_file_name character varying(500)
);
     DROP TABLE public.file_uploads;
       public         heap    bwilliam    false    4                    1259    86152    form_fields    TABLE     )  CREATE TABLE public.form_fields (
    field_id uuid DEFAULT gen_random_uuid() NOT NULL,
    form_id uuid,
    label character varying(255) NOT NULL,
    field_type character varying(50) NOT NULL,
    is_required boolean DEFAULT false,
    options_endpoint character varying(255),
    is_verified boolean DEFAULT false,
    verification_endpoint character varying(255),
    order_index integer NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    options jsonb
);
    DROP TABLE public.form_fields;
       public         heap    bwilliam    false    4                    1259    86143    forms    TABLE     c  CREATE TABLE public.forms (
    form_id uuid DEFAULT gen_random_uuid() NOT NULL,
    form_name character varying(255) NOT NULL,
    verification_endpoint character varying(255),
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    needs_verification boolean DEFAULT false
);
    DROP TABLE public.forms;
       public         heap    bwilliam    false    4         �            1259    86045    fx_rates    TABLE     s  CREATE TABLE public.fx_rates (
    rate_id uuid DEFAULT gen_random_uuid() NOT NULL,
    currency_code character varying(3) NOT NULL,
    rate_date date NOT NULL,
    exchange_rate numeric(12,6) NOT NULL,
    template_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.fx_rates;
       public         heap    bwilliam    false    4         �            1259    85975    media_content    TABLE     �  CREATE TABLE public.media_content (
    content_id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_type character varying(50) NOT NULL,
    content_url character varying(255) NOT NULL,
    assigned_to character varying(50) NOT NULL,
    assigned_id uuid,
    branch_id uuid,
    dispenser_template_id uuid,
    display_template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.media_content;
       public         heap    bwilliam    false    4         �            1259    85599    notification_templates    TABLE     �  CREATE TABLE public.notification_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    template_type character varying(50) NOT NULL,
    subject character varying(255) NOT NULL,
    template_content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 *   DROP TABLE public.notification_templates;
       public         heap    bwilliam    false    4         �            1259    85946    permissions    TABLE     �  CREATE TABLE public.permissions (
    route_path character varying(255) NOT NULL,
    route_method character varying(50) NOT NULL,
    permission_name character varying(255) NOT NULL,
    description text,
    controller_function character varying(100),
    middleware character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL
);
    DROP TABLE public.permissions;
       public         heap    bwilliam    false    4         �            1259    86080    queue    TABLE     M  CREATE TABLE public.queue (
    queue_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    service_id uuid,
    is_default boolean DEFAULT true,
    algorithm character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.queue;
       public         heap    bwilliam    false    4                     1259    86090 
   queue_item    TABLE     c  CREATE TABLE public.queue_item (
    queue_item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    queue_id uuid,
    ticket_id uuid,
    counter_id uuid,
    "position" integer NOT NULL,
    served boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.queue_item;
       public         heap    bwilliam    false    4         �            1259    86089    queue_item_position_seq    SEQUENCE     �   CREATE SEQUENCE public.queue_item_position_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.queue_item_position_seq;
       public          bwilliam    false    256    4         x           0    0    queue_item_position_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.queue_item_position_seq OWNED BY public.queue_item."position";
          public          bwilliam    false    255                    1259    86110 	   queue_log    TABLE     �   CREATE TABLE public.queue_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    action_type character varying(50),
    ticket_id uuid,
    user_id uuid,
    action_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.queue_log;
       public         heap    bwilliam    false    4         �            1259    84913    role_permissions    TABLE     �   CREATE TABLE public.role_permissions (
    role_permission_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid,
    permission_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id uuid
);
 $   DROP TABLE public.role_permissions;
       public         heap    bwilliam    false    4         �            1259    84886    roles    TABLE     �  CREATE TABLE public.roles (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    updated_at timestamp without time zone,
    is_system boolean DEFAULT false,
    CONSTRAINT valid_description CHECK ((length(description) <= 1000))
);
    DROP TABLE public.roles;
       public         heap    bwilliam    false    4         �            1259    85609    sent_notifications    TABLE     *  CREATE TABLE public.sent_notifications (
    notification_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    recipient_id uuid,
    notification_type character varying(50) NOT NULL,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notification_content text
);
 &   DROP TABLE public.sent_notifications;
       public         heap    bwilliam    false    4         �            1259    85795    service    TABLE     <  CREATE TABLE public.service (
    service_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    parent_service_id uuid,
    name character varying(255) NOT NULL,
    label character varying(50),
    image_url character varying(255),
    color character varying(20),
    text_below character varying(255),
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    icon character varying(50),
    estimated_time_minutes integer
);
    DROP TABLE public.service;
       public         heap    bwilliam    false    4         �            1259    85554    service_feedback_settings    TABLE     I  CREATE TABLE public.service_feedback_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    template_id uuid,
    is_feedback_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 -   DROP TABLE public.service_feedback_settings;
       public         heap    bwilliam    false    4                    1259    86168    service_form_mapping    TABLE     �   CREATE TABLE public.service_form_mapping (
    mapping_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    form_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);
 (   DROP TABLE public.service_form_mapping;
       public         heap    bwilliam    false    4         �            1259    85161    service_process    TABLE     �   CREATE TABLE public.service_process (
    service_process_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    name character varying(255) NOT NULL,
    description text,
    order_index integer NOT NULL
);
 #   DROP TABLE public.service_process;
       public         heap    bwilliam    false    4         �            1259    84865    settings    TABLE     �  CREATE TABLE public.settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    logout_code_required boolean DEFAULT false,
    closing_code_required boolean DEFAULT false,
    multiple_closing_codes_required boolean DEFAULT false,
    autocall_starts_seconds integer,
    forced_auto_call_menu_timeout_seconds integer DEFAULT 30,
    start_transaction_automatically_seconds integer DEFAULT 30,
    max_missing_clients_repeated_calls integer,
    put_back_missing_client_time_minutes integer,
    min_waiting_time_on_ticket_minutes integer,
    max_waiting_time_on_ticket_minutes integer,
    place_ticket_to_top_of_queue_when_redirected boolean,
    allow_actions_on_ticket_after_redirected_to_service boolean,
    ticket_validity_time_for_customer_feedback_minutes integer,
    sorting_method_of_waiting_tickets character varying(255),
    waiting_time_calculation_source character varying(255),
    num_days_to_calculate_average_waiting_time_of_services integer,
    method_of_calculating_number_of_people_waiting character varying(255),
    enable_virtual_ticket_option boolean,
    identified_client_for_appointment boolean,
    default_signal_type integer,
    smtp_port_number integer,
    smtp_host_name character varying(255),
    smtp_user_name character varying(255),
    smtp_password character varying(255),
    smtp_sender_email_address character varying(255),
    appointment_sender_email character varying(255),
    smtp_ssl boolean,
    smtp_starttls boolean,
    disable_send_same_email_seconds integer,
    license_certificate_notification_email_address character varying(255),
    smpp_host character varying(255),
    smpp_port integer,
    system_id character varying(255),
    smpp_password character varying(255),
    source_address_ton integer,
    source_address_npi integer,
    source_phone_number character varying(255),
    destination_address_ton integer,
    destination_address_npi integer,
    sms_text_encoding character varying(255),
    enable_multipart_messages boolean,
    phone_number character varying(20),
    sms_text text,
    disable_ads_on_ticket_dispenser boolean,
    idle_time_before_displaying_ads_on_ticket_dispenser_seconds integer,
    ads_changing_time_on_ticket_dispenser_seconds integer,
    disable_ads_on_feedback_device boolean,
    idle_time_before_showing_ads_on_feedback_device_seconds integer,
    switch_between_ads_on_feedback_device_seconds integer,
    statistics_export_email_address character varying(255),
    statistics_export_subject character varying(255),
    user_identification_system_type character varying(255),
    user_authentication_method character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    CONSTRAINT settings_autocall_starts_seconds_check CHECK (((autocall_starts_seconds >= 1) AND (autocall_starts_seconds <= 30)))
);
    DROP TABLE public.settings;
       public         heap    bwilliam    false    4         �            1259    84829    sms_api    TABLE     �  CREATE TABLE public.sms_api (
    sms_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    provider character varying(255) NOT NULL,
    api_key character varying(255) NOT NULL,
    username character varying(255),
    password character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
    DROP TABLE public.sms_api;
       public         heap    bwilliam    false    4         �            1259    84814    smtp_config    TABLE     �  CREATE TABLE public.smtp_config (
    smtp_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    host character varying(255) NOT NULL,
    port integer NOT NULL,
    username character varying(255),
    password character varying(255),
    encryption character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);
    DROP TABLE public.smtp_config;
       public         heap    bwilliam    false    4         �            1259    85490    survey_question_answers    TABLE       CREATE TABLE public.survey_question_answers (
    answer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid,
    answer_text text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 +   DROP TABLE public.survey_question_answers;
       public         heap    bwilliam    false    4         �            1259    85473    survey_questions    TABLE     �  CREATE TABLE public.survey_questions (
    question_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    question_text text NOT NULL,
    is_mandatory boolean,
    question_type character varying(50) NOT NULL,
    thank_you_sms_status boolean DEFAULT false,
    whatsapp_sms_status boolean DEFAULT false,
    whatsapp_sms_content text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.survey_questions;
       public         heap    bwilliam    false    4         �            1259    85505    survey_responses    TABLE     �  CREATE TABLE public.survey_responses (
    response_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    branch_id uuid,
    customer_id uuid,
    user_id uuid,
    counter_id uuid,
    service_id uuid,
    dispenser_id uuid,
    question_id uuid,
    response_data jsonb,
    rating integer,
    comment text,
    selected_option character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.survey_responses;
       public         heap    bwilliam    false    4         �            1259    85465    survey_templates    TABLE       CREATE TABLE public.survey_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.survey_templates;
       public         heap    bwilliam    false    4         �            1259    85810    ticket    TABLE     s  CREATE TABLE public.ticket (
    ticket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    service_id uuid,
    customer_id uuid,
    token_number character varying(100),
    generated_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(50) DEFAULT 'Pending'::character varying,
    queue_position integer,
    current_user_id uuid,
    last_updated_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    dispenser_id uuid,
    transferred boolean DEFAULT false,
    picked_up boolean DEFAULT false,
    picked_up_by uuid,
    additional_info jsonb,
    form_id uuid
);
    DROP TABLE public.ticket;
       public         heap    bwilliam    false    4         �            1259    85314    ticket_action_log    TABLE     #  CREATE TABLE public.ticket_action_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    user_id uuid,
    counter_id uuid,
    action character varying(50) NOT NULL,
    action_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    additional_info jsonb
);
 %   DROP TABLE public.ticket_action_log;
       public         heap    bwilliam    false    4         �            1259    85830    ticket_assignments    TABLE     +  CREATE TABLE public.ticket_assignments (
    assignment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    assigned_user_id uuid,
    assigned_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    resolved boolean DEFAULT false,
    resolved_time timestamp with time zone
);
 &   DROP TABLE public.ticket_assignments;
       public         heap    bwilliam    false    4         �            1259    85338    ticket_management_settings    TABLE     �  CREATE TABLE public.ticket_management_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    enable_language_change boolean DEFAULT false,
    enable_fullscreen_mode boolean DEFAULT false,
    enable_print_option boolean DEFAULT false,
    disable_cancel_button_mobile boolean DEFAULT false,
    enable_disable_settings boolean DEFAULT false,
    show_token_popup boolean DEFAULT false,
    queue_form_display boolean DEFAULT false,
    category_order_by_name boolean DEFAULT false,
    name_display_on_ticket boolean DEFAULT false,
    logo_on_ticket_screen boolean DEFAULT false,
    company_name_on_ticket boolean DEFAULT false,
    create_multiple_ticket_same_number boolean DEFAULT false,
    display_panel_name_on_ticket boolean DEFAULT false,
    redirect_to_other_website boolean DEFAULT false,
    show_qr_code boolean DEFAULT false,
    show_progress_bar boolean DEFAULT false,
    show_acronym_booking_system boolean DEFAULT false,
    show_categories_on_print_ticket boolean DEFAULT false,
    category_in_row integer DEFAULT 1,
    category_text_font_size character varying(20),
    ticket_font_family character varying(50),
    border_size character varying(20),
    token_number_digit integer DEFAULT 3,
    token_start_from character varying(20) DEFAULT '001'::character varying,
    service_estimate_time integer DEFAULT 10,
    calculate_estimate_waiting_time boolean DEFAULT false,
    category_level_count_waiting_time boolean DEFAULT false,
    ticket_message_1_enable_disable boolean DEFAULT false,
    ticket_message_2_enable_disable boolean DEFAULT false,
    ticket_message_1 character varying(255),
    ticket_message_2 character varying(255),
    capacity_management_enable_disable boolean DEFAULT false,
    capacity_limits integer DEFAULT 0,
    late_coming_feature_enable_disable boolean DEFAULT false,
    multiple_ticket_for_same_customer_enable_disable boolean DEFAULT false,
    fixed_time_enable_disable boolean DEFAULT false,
    enter_time_in_minutes integer DEFAULT 0,
    ticket_generate_if_no_call_enable_disable boolean DEFAULT false,
    restrict_user_to_generate_ticket_enable_disable boolean DEFAULT false,
    custom_css text
);
 .   DROP TABLE public.ticket_management_settings;
       public         heap    bwilliam    false    4         �            1259    85195    ticket_process    TABLE     o  CREATE TABLE public.ticket_process (
    ticket_process_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    service_process_id uuid,
    counter_id uuid,
    user_id uuid,
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    end_time timestamp with time zone,
    status character varying(50) DEFAULT 'Pending'::character varying
);
 "   DROP TABLE public.ticket_process;
       public         heap    bwilliam    false    4         �            1259    85903    ticket_workflow_history    TABLE       CREATE TABLE public.ticket_workflow_history (
    history_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    from_stage_id uuid,
    to_stage_id uuid,
    transition_id uuid,
    transition_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 +   DROP TABLE public.ticket_workflow_history;
       public         heap    bwilliam    false    4         �            1259    85235    user_branch    TABLE     �   CREATE TABLE public.user_branch (
    user_branch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    branch_id uuid
);
    DROP TABLE public.user_branch;
       public         heap    bwilliam    false    4         �            1259    85251    user_counter    TABLE     �   CREATE TABLE public.user_counter (
    user_counter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    counter_id uuid
);
     DROP TABLE public.user_counter;
       public         heap    bwilliam    false    4         �            1259    85959 
   user_roles    TABLE     �   CREATE TABLE public.user_roles (
    user_role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    role_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.user_roles;
       public         heap    bwilliam    false    4         �            1259    84946    users    TABLE     �  CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    date_of_birth date,
    phone_number character varying(20),
    profile_picture_url character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp with time zone,
    is_active boolean DEFAULT true,
    is_system_admin boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verification_token character varying(255),
    reset_password_token character varying(255),
    reset_password_expiration timestamp with time zone,
    is_owner boolean DEFAULT false,
    updated_at timestamp without time zone,
    complete_kyc boolean DEFAULT false,
    approved_at timestamp without time zone,
    is_approved boolean DEFAULT false,
    branch_id uuid
);
    DROP TABLE public.users;
       public         heap    bwilliam    false    4         �            1259    85656    voice_notification_logs    TABLE     �   CREATE TABLE public.voice_notification_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    recipient_id uuid,
    played_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 +   DROP TABLE public.voice_notification_logs;
       public         heap    bwilliam    false    4         �            1259    85646    voice_notification_templates    TABLE     �  CREATE TABLE public.voice_notification_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    template_content text NOT NULL,
    font_size character varying(20),
    color character varying(20),
    voice_message_text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 0   DROP TABLE public.voice_notification_templates;
       public         heap    bwilliam    false    4         �            1259    85879    workflow_stages    TABLE     �   CREATE TABLE public.workflow_stages (
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    stage_name character varying(100) NOT NULL,
    description text
);
 #   DROP TABLE public.workflow_stages;
       public         heap    bwilliam    false    4         �            1259    85887    workflow_transitions    TABLE     �   CREATE TABLE public.workflow_transitions (
    transition_id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_stage_id uuid,
    to_stage_id uuid,
    condition character varying(255)
);
 (   DROP TABLE public.workflow_transitions;
       public         heap    bwilliam    false    4         �           2604    86094    queue_item position    DEFAULT     |   ALTER TABLE ONLY public.queue_item ALTER COLUMN "position" SET DEFAULT nextval('public.queue_item_position_seq'::regclass);
 D   ALTER TABLE public.queue_item ALTER COLUMN "position" DROP DEFAULT;
       public          bwilliam    false    256    255    256         >          0    84799    active_directory 
   TABLE DATA           �   COPY public.active_directory (ad_id, company_id, domain_name, username, password, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    211       4158.dat =          0    84767    branch 
   TABLE DATA           �   COPY public.branch (branch_id, company_id, name, portal_code, closing_type, closing_time, default_language, time_zone, enable_appointment, smart_ticket, status, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    210       4157.dat <          0    84757    company 
   TABLE DATA           n   COPY public.company (company_id, name, address, phone, email, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    209       4156.dat F          0    85144    counter 
   TABLE DATA           j   COPY public.counter (counter_id, branch_id, name, status, service_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    219       4166.dat m          0    86122    counter_ticket 
   TABLE DATA           n   COPY public.counter_ticket (counter_ticket_id, counter_id, ticket_id, assigned_timestamp, served) FROM stdin;
    public          bwilliam    false    258       4205.dat M          0    85455 	   customers 
   TABLE DATA           �   COPY public.customers (customer_id, first_name, last_name, email, phone_number, address, city, state, country, postal_code, created_at, updated_at) FROM stdin;
    public          bwilliam    false    226       4173.dat [          0    85785    device_logs 
   TABLE DATA           �   COPY public.device_logs (device_id, device_name, device_type, location, ip_address, last_connection, connection_status, connection_log, created_at, updated_at) FROM stdin;
    public          bwilliam    false    240       4187.dat f          0    86004    devices 
   TABLE DATA           �  COPY public.devices (device_id, branch_id, device_name, device_type, ip_address, authentication_code, license_key, validity_starts, validity_ends, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, special_service, agent_info, is_activated, created_at, updated_at, created_by, activation_status, activated_at) FROM stdin;
    public          bwilliam    false    251       4198.dat A          0    84845 	   dispenser 
   TABLE DATA           �  COPY public.dispenser (dispenser_id, branch_id, name, language, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, validity_starts, validity_ends, special_service, agent_name, agent_ip, authentication_key, status, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    214       4161.dat Z          0    85757    dispenser_device_templates 
   TABLE DATA           x   COPY public.dispenser_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    239       4186.dat Y          0    85742    dispenser_templates 
   TABLE DATA           �   COPY public.dispenser_templates (template_id, template_name, branch_id, template_type, background_color, created_at, updated_at, background_video, background_image, assigned_to, news_scroll) FROM stdin;
    public          bwilliam    false    238       4185.dat X          0    85691    display_device_templates 
   TABLE DATA           v   COPY public.display_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    237       4184.dat W          0    85668    display_devices 
   TABLE DATA           �   COPY public.display_devices (device_id, branch_id, device_name, ip_address, authentication_code, created_at, updated_at) FROM stdin;
    public          bwilliam    false    236       4183.dat d          0    85965    display_templates 
   TABLE DATA           �  COPY public.display_templates (template_id, template_name, background_image, background_color, split_type, page_style, name_on_display_screen, need_mobile_screen, show_skip_call, show_waiting_call, skip_closed_call, display_screen_tune, show_queue_number, show_missed_queue_number, full_screen_option, show_disclaimer_message, show_missed_queue_with_marquee, template_type, content_source_type, content_endpoint, content_source, section_division, content_configuration, created_at, updated_at) FROM stdin;
    public          bwilliam    false    249       4196.dat g          0    86032    file_uploads 
   TABLE DATA           �   COPY public.file_uploads (upload_id, folder_name, folder_location, file_name, file_type, created_at, upload_for, uploaded_by, old_file_name) FROM stdin;
    public          bwilliam    false    252       4199.dat o          0    86152    form_fields 
   TABLE DATA           �   COPY public.form_fields (field_id, form_id, label, field_type, is_required, options_endpoint, is_verified, verification_endpoint, order_index, created_by, created_at, updated_at, options) FROM stdin;
    public          bwilliam    false    260       4207.dat n          0    86143    forms 
   TABLE DATA           �   COPY public.forms (form_id, form_name, verification_endpoint, created_by, created_at, updated_at, needs_verification) FROM stdin;
    public          bwilliam    false    259       4206.dat h          0    86045    fx_rates 
   TABLE DATA           y   COPY public.fx_rates (rate_id, currency_code, rate_date, exchange_rate, template_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    253       4200.dat e          0    85975    media_content 
   TABLE DATA           �   COPY public.media_content (content_id, content_type, content_url, assigned_to, assigned_id, branch_id, dispenser_template_id, display_template_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    250       4197.dat S          0    85599    notification_templates 
   TABLE DATA           �   COPY public.notification_templates (template_id, template_name, template_type, subject, template_content, created_at, updated_at) FROM stdin;
    public          bwilliam    false    232       4179.dat b          0    85946    permissions 
   TABLE DATA           �   COPY public.permissions (route_path, route_method, permission_name, description, controller_function, middleware, created_at, updated_at, permission_id) FROM stdin;
    public          bwilliam    false    247       4194.dat i          0    86080    queue 
   TABLE DATA           o   COPY public.queue (queue_id, branch_id, service_id, is_default, algorithm, created_at, updated_at) FROM stdin;
    public          bwilliam    false    254       4201.dat k          0    86090 
   queue_item 
   TABLE DATA           �   COPY public.queue_item (queue_item_id, queue_id, ticket_id, counter_id, "position", served, created_at, updated_at) FROM stdin;
    public          bwilliam    false    256       4203.dat l          0    86110 	   queue_log 
   TABLE DATA           ^   COPY public.queue_log (log_id, action_type, ticket_id, user_id, action_timestamp) FROM stdin;
    public          bwilliam    false    257       4204.dat D          0    84913    role_permissions 
   TABLE DATA           m   COPY public.role_permissions (role_permission_id, role_id, permission_id, created_at, tenant_id) FROM stdin;
    public          bwilliam    false    217       4164.dat C          0    84886    roles 
   TABLE DATA           n   COPY public.roles (role_id, role_name, description, created_at, is_active, updated_at, is_system) FROM stdin;
    public          bwilliam    false    216       4163.dat T          0    85609    sent_notifications 
   TABLE DATA           �   COPY public.sent_notifications (notification_id, template_id, recipient_id, notification_type, sent_at, notification_content) FROM stdin;
    public          bwilliam    false    233       4180.dat \          0    85795    service 
   TABLE DATA           �   COPY public.service (service_id, branch_id, parent_service_id, name, label, image_url, color, text_below, description, created_at, updated_at, created_by, icon, estimated_time_minutes) FROM stdin;
    public          bwilliam    false    241       4188.dat R          0    85554    service_feedback_settings 
   TABLE DATA           �   COPY public.service_feedback_settings (setting_id, service_id, template_id, is_feedback_enabled, created_at, updated_at) FROM stdin;
    public          bwilliam    false    231       4178.dat p          0    86168    service_form_mapping 
   TABLE DATA           g   COPY public.service_form_mapping (mapping_id, service_id, form_id, created_at, updated_at) FROM stdin;
    public          bwilliam    false    261       4208.dat G          0    85161    service_process 
   TABLE DATA           i   COPY public.service_process (service_process_id, service_id, name, description, order_index) FROM stdin;
    public          bwilliam    false    220       4167.dat B          0    84865    settings 
   TABLE DATA           �  COPY public.settings (setting_id, company_id, logout_code_required, closing_code_required, multiple_closing_codes_required, autocall_starts_seconds, forced_auto_call_menu_timeout_seconds, start_transaction_automatically_seconds, max_missing_clients_repeated_calls, put_back_missing_client_time_minutes, min_waiting_time_on_ticket_minutes, max_waiting_time_on_ticket_minutes, place_ticket_to_top_of_queue_when_redirected, allow_actions_on_ticket_after_redirected_to_service, ticket_validity_time_for_customer_feedback_minutes, sorting_method_of_waiting_tickets, waiting_time_calculation_source, num_days_to_calculate_average_waiting_time_of_services, method_of_calculating_number_of_people_waiting, enable_virtual_ticket_option, identified_client_for_appointment, default_signal_type, smtp_port_number, smtp_host_name, smtp_user_name, smtp_password, smtp_sender_email_address, appointment_sender_email, smtp_ssl, smtp_starttls, disable_send_same_email_seconds, license_certificate_notification_email_address, smpp_host, smpp_port, system_id, smpp_password, source_address_ton, source_address_npi, source_phone_number, destination_address_ton, destination_address_npi, sms_text_encoding, enable_multipart_messages, phone_number, sms_text, disable_ads_on_ticket_dispenser, idle_time_before_displaying_ads_on_ticket_dispenser_seconds, ads_changing_time_on_ticket_dispenser_seconds, disable_ads_on_feedback_device, idle_time_before_showing_ads_on_feedback_device_seconds, switch_between_ads_on_feedback_device_seconds, statistics_export_email_address, statistics_export_subject, user_identification_system_type, user_authentication_method, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    215       4162.dat @          0    84829    sms_api 
   TABLE DATA           �   COPY public.sms_api (sms_id, company_id, provider, api_key, username, password, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    213       4160.dat ?          0    84814    smtp_config 
   TABLE DATA           �   COPY public.smtp_config (smtp_id, company_id, host, port, username, password, encryption, created_at, updated_at, created_by) FROM stdin;
    public          bwilliam    false    212       4159.dat P          0    85490    survey_question_answers 
   TABLE DATA           n   COPY public.survey_question_answers (answer_id, question_id, answer_text, created_at, updated_at) FROM stdin;
    public          bwilliam    false    229       4176.dat O          0    85473    survey_questions 
   TABLE DATA           �   COPY public.survey_questions (question_id, template_id, question_text, is_mandatory, question_type, thank_you_sms_status, whatsapp_sms_status, whatsapp_sms_content, created_at, updated_at) FROM stdin;
    public          bwilliam    false    228       4175.dat Q          0    85505    survey_responses 
   TABLE DATA           �   COPY public.survey_responses (response_id, template_id, branch_id, customer_id, user_id, counter_id, service_id, dispenser_id, question_id, response_data, rating, comment, selected_option, created_at) FROM stdin;
    public          bwilliam    false    230       4177.dat N          0    85465    survey_templates 
   TABLE DATA           ^   COPY public.survey_templates (template_id, template_name, created_at, updated_at) FROM stdin;
    public          bwilliam    false    227       4174.dat ]          0    85810    ticket 
   TABLE DATA           �   COPY public.ticket (ticket_id, branch_id, service_id, customer_id, token_number, generated_time, status, queue_position, current_user_id, last_updated_time, dispenser_id, transferred, picked_up, picked_up_by, additional_info, form_id) FROM stdin;
    public          bwilliam    false    242       4189.dat K          0    85314    ticket_action_log 
   TABLE DATA           y   COPY public.ticket_action_log (log_id, ticket_id, user_id, counter_id, action, action_time, additional_info) FROM stdin;
    public          bwilliam    false    224       4171.dat ^          0    85830    ticket_assignments 
   TABLE DATA           �   COPY public.ticket_assignments (assignment_id, ticket_id, assigned_user_id, assigned_time, resolved, resolved_time) FROM stdin;
    public          bwilliam    false    243       4190.dat L          0    85338    ticket_management_settings 
   TABLE DATA           T  COPY public.ticket_management_settings (setting_id, enable_language_change, enable_fullscreen_mode, enable_print_option, disable_cancel_button_mobile, enable_disable_settings, show_token_popup, queue_form_display, category_order_by_name, name_display_on_ticket, logo_on_ticket_screen, company_name_on_ticket, create_multiple_ticket_same_number, display_panel_name_on_ticket, redirect_to_other_website, show_qr_code, show_progress_bar, show_acronym_booking_system, show_categories_on_print_ticket, category_in_row, category_text_font_size, ticket_font_family, border_size, token_number_digit, token_start_from, service_estimate_time, calculate_estimate_waiting_time, category_level_count_waiting_time, ticket_message_1_enable_disable, ticket_message_2_enable_disable, ticket_message_1, ticket_message_2, capacity_management_enable_disable, capacity_limits, late_coming_feature_enable_disable, multiple_ticket_for_same_customer_enable_disable, fixed_time_enable_disable, enter_time_in_minutes, ticket_generate_if_no_call_enable_disable, restrict_user_to_generate_ticket_enable_disable, custom_css) FROM stdin;
    public          bwilliam    false    225       4172.dat H          0    85195    ticket_process 
   TABLE DATA           �   COPY public.ticket_process (ticket_process_id, ticket_id, service_process_id, counter_id, user_id, start_time, end_time, status) FROM stdin;
    public          bwilliam    false    221       4168.dat a          0    85903    ticket_workflow_history 
   TABLE DATA           �   COPY public.ticket_workflow_history (history_id, ticket_id, from_stage_id, to_stage_id, transition_id, transition_timestamp) FROM stdin;
    public          bwilliam    false    246       4193.dat I          0    85235    user_branch 
   TABLE DATA           I   COPY public.user_branch (user_branch_id, user_id, branch_id) FROM stdin;
    public          bwilliam    false    222       4169.dat J          0    85251    user_counter 
   TABLE DATA           L   COPY public.user_counter (user_counter_id, user_id, counter_id) FROM stdin;
    public          bwilliam    false    223       4170.dat c          0    85959 
   user_roles 
   TABLE DATA           P   COPY public.user_roles (user_role_id, user_id, role_id, created_at) FROM stdin;
    public          bwilliam    false    248       4195.dat E          0    84946    users 
   TABLE DATA           [  COPY public.users (user_id, username, email, password, first_name, last_name, date_of_birth, phone_number, profile_picture_url, created_at, last_login, is_active, is_system_admin, is_verified, verification_token, reset_password_token, reset_password_expiration, is_owner, updated_at, complete_kyc, approved_at, is_approved, branch_id) FROM stdin;
    public          bwilliam    false    218       4165.dat V          0    85656    voice_notification_logs 
   TABLE DATA           _   COPY public.voice_notification_logs (log_id, template_id, recipient_id, played_at) FROM stdin;
    public          bwilliam    false    235       4182.dat U          0    85646    voice_notification_templates 
   TABLE DATA           �   COPY public.voice_notification_templates (template_id, template_name, template_content, font_size, color, voice_message_text, created_at, updated_at) FROM stdin;
    public          bwilliam    false    234       4181.dat _          0    85879    workflow_stages 
   TABLE DATA           L   COPY public.workflow_stages (stage_id, stage_name, description) FROM stdin;
    public          bwilliam    false    244       4191.dat `          0    85887    workflow_transitions 
   TABLE DATA           d   COPY public.workflow_transitions (transition_id, from_stage_id, to_stage_id, condition) FROM stdin;
    public          bwilliam    false    245       4192.dat y           0    0    queue_item_position_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.queue_item_position_seq', 1, false);
          public          bwilliam    false    255                    2606    84808 &   active_directory active_directory_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.active_directory
    ADD CONSTRAINT active_directory_pkey PRIMARY KEY (ad_id);
 P   ALTER TABLE ONLY public.active_directory DROP CONSTRAINT active_directory_pkey;
       public            bwilliam    false    211                    2606    84777    branch branch_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (branch_id);
 <   ALTER TABLE ONLY public.branch DROP CONSTRAINT branch_pkey;
       public            bwilliam    false    210                     2606    84766    company company_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_pkey PRIMARY KEY (company_id);
 >   ALTER TABLE ONLY public.company DROP CONSTRAINT company_pkey;
       public            bwilliam    false    209                    2606    85150    counter counter_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.counter
    ADD CONSTRAINT counter_pkey PRIMARY KEY (counter_id);
 >   ALTER TABLE ONLY public.counter DROP CONSTRAINT counter_pkey;
       public            bwilliam    false    219         p           2606    86129 "   counter_ticket counter_ticket_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_pkey PRIMARY KEY (counter_ticket_id);
 L   ALTER TABLE ONLY public.counter_ticket DROP CONSTRAINT counter_ticket_pkey;
       public            bwilliam    false    258         *           2606    85464    customers customers_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);
 B   ALTER TABLE ONLY public.customers DROP CONSTRAINT customers_pkey;
       public            bwilliam    false    226         H           2606    85794    device_logs device_logs_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.device_logs
    ADD CONSTRAINT device_logs_pkey PRIMARY KEY (device_id);
 F   ALTER TABLE ONLY public.device_logs DROP CONSTRAINT device_logs_pkey;
       public            bwilliam    false    240         `           2606    86025 G   devices devices_device_name_ip_address_authentication_code_license__key 
   CONSTRAINT     �   ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_device_name_ip_address_authentication_code_license__key UNIQUE (device_name) INCLUDE (ip_address, authentication_code, license_key);
 q   ALTER TABLE ONLY public.devices DROP CONSTRAINT devices_device_name_ip_address_authentication_code_license__key;
       public            bwilliam    false    251    251    251    251         b           2606    86018    devices devices_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (device_id);
 >   ALTER TABLE ONLY public.devices DROP CONSTRAINT devices_pkey;
       public            bwilliam    false    251         F           2606    85764 :   dispenser_device_templates dispenser_device_templates_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_pkey PRIMARY KEY (device_template_id);
 d   ALTER TABLE ONLY public.dispenser_device_templates DROP CONSTRAINT dispenser_device_templates_pkey;
       public            bwilliam    false    239         
           2606    84859    dispenser dispenser_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.dispenser
    ADD CONSTRAINT dispenser_pkey PRIMARY KEY (dispenser_id);
 B   ALTER TABLE ONLY public.dispenser DROP CONSTRAINT dispenser_pkey;
       public            bwilliam    false    214         D           2606    85751 ,   dispenser_templates dispenser_templates_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.dispenser_templates
    ADD CONSTRAINT dispenser_templates_pkey PRIMARY KEY (template_id);
 V   ALTER TABLE ONLY public.dispenser_templates DROP CONSTRAINT dispenser_templates_pkey;
       public            bwilliam    false    238         B           2606    85698 6   display_device_templates display_device_templates_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_pkey PRIMARY KEY (device_template_id);
 `   ALTER TABLE ONLY public.display_device_templates DROP CONSTRAINT display_device_templates_pkey;
       public            bwilliam    false    237         @           2606    85675 $   display_devices display_devices_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.display_devices
    ADD CONSTRAINT display_devices_pkey PRIMARY KEY (device_id);
 N   ALTER TABLE ONLY public.display_devices DROP CONSTRAINT display_devices_pkey;
       public            bwilliam    false    236         \           2606    85974 (   display_templates display_templates_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.display_templates
    ADD CONSTRAINT display_templates_pkey PRIMARY KEY (template_id);
 R   ALTER TABLE ONLY public.display_templates DROP CONSTRAINT display_templates_pkey;
       public            bwilliam    false    249         d           2606    86040    file_uploads file_uploads_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_pkey PRIMARY KEY (upload_id);
 H   ALTER TABLE ONLY public.file_uploads DROP CONSTRAINT file_uploads_pkey;
       public            bwilliam    false    252         t           2606    86162    form_fields form_fields_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.form_fields
    ADD CONSTRAINT form_fields_pkey PRIMARY KEY (field_id);
 F   ALTER TABLE ONLY public.form_fields DROP CONSTRAINT form_fields_pkey;
       public            bwilliam    false    260         r           2606    86151    forms forms_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (form_id);
 :   ALTER TABLE ONLY public.forms DROP CONSTRAINT forms_pkey;
       public            bwilliam    false    259         f           2606    86054 -   fx_rates fx_rates_currency_code_rate_date_key 
   CONSTRAINT     |   ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_currency_code_rate_date_key UNIQUE (currency_code, rate_date);
 W   ALTER TABLE ONLY public.fx_rates DROP CONSTRAINT fx_rates_currency_code_rate_date_key;
       public            bwilliam    false    253    253         h           2606    86052    fx_rates fx_rates_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_pkey PRIMARY KEY (rate_id);
 @   ALTER TABLE ONLY public.fx_rates DROP CONSTRAINT fx_rates_pkey;
       public            bwilliam    false    253         ^           2606    85982     media_content media_content_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT media_content_pkey PRIMARY KEY (content_id);
 J   ALTER TABLE ONLY public.media_content DROP CONSTRAINT media_content_pkey;
       public            bwilliam    false    250         8           2606    85608 2   notification_templates notification_templates_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (template_id);
 \   ALTER TABLE ONLY public.notification_templates DROP CONSTRAINT notification_templates_pkey;
       public            bwilliam    false    232         V           2606    85958 +   permissions permissions_permission_name_key 
   CONSTRAINT     q   ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_permission_name_key UNIQUE (permission_name);
 U   ALTER TABLE ONLY public.permissions DROP CONSTRAINT permissions_permission_name_key;
       public            bwilliam    false    247         X           2606    86681    permissions permissions_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission_id);
 F   ALTER TABLE ONLY public.permissions DROP CONSTRAINT permissions_pkey;
       public            bwilliam    false    247         Z           2606    85956 &   permissions permissions_route_path_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_route_path_key UNIQUE (route_path);
 P   ALTER TABLE ONLY public.permissions DROP CONSTRAINT permissions_route_path_key;
       public            bwilliam    false    247         l           2606    86099    queue_item queue_item_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_pkey PRIMARY KEY (queue_item_id);
 D   ALTER TABLE ONLY public.queue_item DROP CONSTRAINT queue_item_pkey;
       public            bwilliam    false    256         n           2606    86116    queue_log queue_log_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.queue_log
    ADD CONSTRAINT queue_log_pkey PRIMARY KEY (log_id);
 B   ALTER TABLE ONLY public.queue_log DROP CONSTRAINT queue_log_pkey;
       public            bwilliam    false    257         j           2606    86088    queue queue_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.queue
    ADD CONSTRAINT queue_pkey PRIMARY KEY (queue_id);
 :   ALTER TABLE ONLY public.queue DROP CONSTRAINT queue_pkey;
       public            bwilliam    false    254                    2606    84919 &   role_permissions role_permissions_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_permission_id);
 P   ALTER TABLE ONLY public.role_permissions DROP CONSTRAINT role_permissions_pkey;
       public            bwilliam    false    217                    2606    84897    roles roles_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);
 :   ALTER TABLE ONLY public.roles DROP CONSTRAINT roles_pkey;
       public            bwilliam    false    216                    2606    84899    roles roles_role_name_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);
 C   ALTER TABLE ONLY public.roles DROP CONSTRAINT roles_role_name_key;
       public            bwilliam    false    216         :           2606    85617 *   sent_notifications sent_notifications_pkey 
   CONSTRAINT     u   ALTER TABLE ONLY public.sent_notifications
    ADD CONSTRAINT sent_notifications_pkey PRIMARY KEY (notification_id);
 T   ALTER TABLE ONLY public.sent_notifications DROP CONSTRAINT sent_notifications_pkey;
       public            bwilliam    false    233         4           2606    85562 8   service_feedback_settings service_feedback_settings_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_pkey PRIMARY KEY (setting_id);
 b   ALTER TABLE ONLY public.service_feedback_settings DROP CONSTRAINT service_feedback_settings_pkey;
       public            bwilliam    false    231         6           2606    85564 :   service_feedback_settings service_feedback_settings_unique 
   CONSTRAINT     �   ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_unique UNIQUE (service_id, template_id);
 d   ALTER TABLE ONLY public.service_feedback_settings DROP CONSTRAINT service_feedback_settings_unique;
       public            bwilliam    false    231    231         v           2606    86173 .   service_form_mapping service_form_mapping_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_pkey PRIMARY KEY (mapping_id);
 X   ALTER TABLE ONLY public.service_form_mapping DROP CONSTRAINT service_form_mapping_pkey;
       public            bwilliam    false    261         x           2606    86186 @   service_form_mapping service_form_mapping_service_id_form_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_service_id_form_id_key UNIQUE (service_id) INCLUDE (form_id);
 j   ALTER TABLE ONLY public.service_form_mapping DROP CONSTRAINT service_form_mapping_service_id_form_id_key;
       public            bwilliam    false    261    261         J           2606    85804    service service_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (service_id);
 >   ALTER TABLE ONLY public.service DROP CONSTRAINT service_pkey;
       public            bwilliam    false    241                    2606    85168 $   service_process service_process_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.service_process
    ADD CONSTRAINT service_process_pkey PRIMARY KEY (service_process_id);
 N   ALTER TABLE ONLY public.service_process DROP CONSTRAINT service_process_pkey;
       public            bwilliam    false    220                    2606    84880    settings settings_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);
 @   ALTER TABLE ONLY public.settings DROP CONSTRAINT settings_pkey;
       public            bwilliam    false    215                    2606    84838    sms_api sms_api_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.sms_api
    ADD CONSTRAINT sms_api_pkey PRIMARY KEY (sms_id);
 >   ALTER TABLE ONLY public.sms_api DROP CONSTRAINT sms_api_pkey;
       public            bwilliam    false    213                    2606    84823    smtp_config smtp_config_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.smtp_config
    ADD CONSTRAINT smtp_config_pkey PRIMARY KEY (smtp_id);
 F   ALTER TABLE ONLY public.smtp_config DROP CONSTRAINT smtp_config_pkey;
       public            bwilliam    false    212         0           2606    85499 4   survey_question_answers survey_question_answers_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.survey_question_answers
    ADD CONSTRAINT survey_question_answers_pkey PRIMARY KEY (answer_id);
 ^   ALTER TABLE ONLY public.survey_question_answers DROP CONSTRAINT survey_question_answers_pkey;
       public            bwilliam    false    229         .           2606    85484 &   survey_questions survey_questions_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_pkey PRIMARY KEY (question_id);
 P   ALTER TABLE ONLY public.survey_questions DROP CONSTRAINT survey_questions_pkey;
       public            bwilliam    false    228         2           2606    85513 &   survey_responses survey_responses_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_pkey PRIMARY KEY (response_id);
 P   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_pkey;
       public            bwilliam    false    230         ,           2606    85472 &   survey_templates survey_templates_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.survey_templates
    ADD CONSTRAINT survey_templates_pkey PRIMARY KEY (template_id);
 P   ALTER TABLE ONLY public.survey_templates DROP CONSTRAINT survey_templates_pkey;
       public            bwilliam    false    227         &           2606    85322 (   ticket_action_log ticket_action_log_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_pkey PRIMARY KEY (log_id);
 R   ALTER TABLE ONLY public.ticket_action_log DROP CONSTRAINT ticket_action_log_pkey;
       public            bwilliam    false    224         N           2606    85837 *   ticket_assignments ticket_assignments_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_pkey PRIMARY KEY (assignment_id);
 T   ALTER TABLE ONLY public.ticket_assignments DROP CONSTRAINT ticket_assignments_pkey;
       public            bwilliam    false    243         (           2606    85379 :   ticket_management_settings ticket_management_settings_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ticket_management_settings
    ADD CONSTRAINT ticket_management_settings_pkey PRIMARY KEY (setting_id);
 d   ALTER TABLE ONLY public.ticket_management_settings DROP CONSTRAINT ticket_management_settings_pkey;
       public            bwilliam    false    225         L           2606    85822    ticket ticket_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (ticket_id);
 <   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_pkey;
       public            bwilliam    false    242                     2606    85202 "   ticket_process ticket_process_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_pkey PRIMARY KEY (ticket_process_id);
 L   ALTER TABLE ONLY public.ticket_process DROP CONSTRAINT ticket_process_pkey;
       public            bwilliam    false    221         T           2606    85909 4   ticket_workflow_history ticket_workflow_history_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_pkey PRIMARY KEY (history_id);
 ^   ALTER TABLE ONLY public.ticket_workflow_history DROP CONSTRAINT ticket_workflow_history_pkey;
       public            bwilliam    false    246                    2606    84921 '   role_permissions unique_role_permission 
   CONSTRAINT        ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id, tenant_id);
 Q   ALTER TABLE ONLY public.role_permissions DROP CONSTRAINT unique_role_permission;
       public            bwilliam    false    217    217    217         "           2606    85240    user_branch user_branch_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_pkey PRIMARY KEY (user_branch_id);
 F   ALTER TABLE ONLY public.user_branch DROP CONSTRAINT user_branch_pkey;
       public            bwilliam    false    222         $           2606    85256    user_counter user_counter_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_pkey PRIMARY KEY (user_counter_id);
 H   ALTER TABLE ONLY public.user_counter DROP CONSTRAINT user_counter_pkey;
       public            bwilliam    false    223                    2606    84962    users users_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_key;
       public            bwilliam    false    218                    2606    84960    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            bwilliam    false    218                    2606    84964    users users_username_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);
 B   ALTER TABLE ONLY public.users DROP CONSTRAINT users_username_key;
       public            bwilliam    false    218         >           2606    85662 4   voice_notification_logs voice_notification_logs_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.voice_notification_logs
    ADD CONSTRAINT voice_notification_logs_pkey PRIMARY KEY (log_id);
 ^   ALTER TABLE ONLY public.voice_notification_logs DROP CONSTRAINT voice_notification_logs_pkey;
       public            bwilliam    false    235         <           2606    85655 >   voice_notification_templates voice_notification_templates_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.voice_notification_templates
    ADD CONSTRAINT voice_notification_templates_pkey PRIMARY KEY (template_id);
 h   ALTER TABLE ONLY public.voice_notification_templates DROP CONSTRAINT voice_notification_templates_pkey;
       public            bwilliam    false    234         P           2606    85886 $   workflow_stages workflow_stages_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.workflow_stages
    ADD CONSTRAINT workflow_stages_pkey PRIMARY KEY (stage_id);
 N   ALTER TABLE ONLY public.workflow_stages DROP CONSTRAINT workflow_stages_pkey;
       public            bwilliam    false    244         R           2606    85892 .   workflow_transitions workflow_transitions_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (transition_id);
 X   ALTER TABLE ONLY public.workflow_transitions DROP CONSTRAINT workflow_transitions_pkey;
       public            bwilliam    false    245         �           2620    86661 #   ticket ticket_status_update_trigger    TRIGGER     �   CREATE TRIGGER ticket_status_update_trigger AFTER UPDATE OF status ON public.ticket FOR EACH ROW WHEN (((old.status)::text <> (new.status)::text)) EXECUTE FUNCTION public.update_ticket_position();
 <   DROP TRIGGER ticket_status_update_trigger ON public.ticket;
       public          bwilliam    false    242    242    274    242         z           2606    84809 1   active_directory active_directory_company_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.active_directory
    ADD CONSTRAINT active_directory_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);
 [   ALTER TABLE ONLY public.active_directory DROP CONSTRAINT active_directory_company_id_fkey;
       public          bwilliam    false    3840    209    211         y           2606    84778    branch branch_company_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);
 G   ALTER TABLE ONLY public.branch DROP CONSTRAINT branch_company_id_fkey;
       public          bwilliam    false    209    3840    210         �           2606    85151    counter counter_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.counter
    ADD CONSTRAINT counter_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 H   ALTER TABLE ONLY public.counter DROP CONSTRAINT counter_branch_id_fkey;
       public          bwilliam    false    210    3842    219         �           2606    86130 -   counter_ticket counter_ticket_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 W   ALTER TABLE ONLY public.counter_ticket DROP CONSTRAINT counter_ticket_counter_id_fkey;
       public          bwilliam    false    219    3868    258         �           2606    86135 ,   counter_ticket counter_ticket_ticket_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id);
 V   ALTER TABLE ONLY public.counter_ticket DROP CONSTRAINT counter_ticket_ticket_id_fkey;
       public          bwilliam    false    258    242    3916         �           2606    86019    devices devices_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 H   ALTER TABLE ONLY public.devices DROP CONSTRAINT devices_branch_id_fkey;
       public          bwilliam    false    251    3842    210         }           2606    84860 "   dispenser dispenser_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispenser
    ADD CONSTRAINT dispenser_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 L   ALTER TABLE ONLY public.dispenser DROP CONSTRAINT dispenser_branch_id_fkey;
       public          bwilliam    false    3842    214    210         �           2606    85765 D   dispenser_device_templates dispenser_device_templates_device_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.dispenser(dispenser_id);
 n   ALTER TABLE ONLY public.dispenser_device_templates DROP CONSTRAINT dispenser_device_templates_device_id_fkey;
       public          bwilliam    false    3850    239    214         �           2606    85770 F   dispenser_device_templates dispenser_device_templates_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id);
 p   ALTER TABLE ONLY public.dispenser_device_templates DROP CONSTRAINT dispenser_device_templates_template_id_fkey;
       public          bwilliam    false    238    239    3908         �           2606    85752 6   dispenser_templates dispenser_templates_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispenser_templates
    ADD CONSTRAINT dispenser_templates_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 `   ALTER TABLE ONLY public.dispenser_templates DROP CONSTRAINT dispenser_templates_branch_id_fkey;
       public          bwilliam    false    210    3842    238         �           2606    86070 @   display_device_templates display_device_templates_device_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) NOT VALID;
 j   ALTER TABLE ONLY public.display_device_templates DROP CONSTRAINT display_device_templates_device_id_fkey;
       public          bwilliam    false    251    237    3938         �           2606    86065 B   display_device_templates display_device_templates_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id) NOT VALID;
 l   ALTER TABLE ONLY public.display_device_templates DROP CONSTRAINT display_device_templates_template_id_fkey;
       public          bwilliam    false    238    237    3908         �           2606    85676 .   display_devices display_devices_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.display_devices
    ADD CONSTRAINT display_devices_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 X   ALTER TABLE ONLY public.display_devices DROP CONSTRAINT display_devices_branch_id_fkey;
       public          bwilliam    false    3842    210    236         �           2606    85983 #   media_content fk_dispenser_template    FK CONSTRAINT     �   ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT fk_dispenser_template FOREIGN KEY (dispenser_template_id) REFERENCES public.dispenser_templates(template_id);
 M   ALTER TABLE ONLY public.media_content DROP CONSTRAINT fk_dispenser_template;
       public          bwilliam    false    3908    238    250         �           2606    85988 !   media_content fk_display_template    FK CONSTRAINT     �   ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT fk_display_template FOREIGN KEY (display_template_id) REFERENCES public.display_templates(template_id);
 K   ALTER TABLE ONLY public.media_content DROP CONSTRAINT fk_display_template;
       public          bwilliam    false    250    3932    249         �           2606    86163 $   form_fields form_fields_form_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.form_fields
    ADD CONSTRAINT form_fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id) ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.form_fields DROP CONSTRAINT form_fields_form_id_fkey;
       public          bwilliam    false    259    260    3954         �           2606    86075 "   fx_rates fx_rates_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id) NOT VALID;
 L   ALTER TABLE ONLY public.fx_rates DROP CONSTRAINT fx_rates_template_id_fkey;
       public          bwilliam    false    253    3908    238         �           2606    86105 %   queue_item queue_item_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 O   ALTER TABLE ONLY public.queue_item DROP CONSTRAINT queue_item_counter_id_fkey;
       public          bwilliam    false    256    219    3868         �           2606    86100 #   queue_item queue_item_queue_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.queue(queue_id);
 M   ALTER TABLE ONLY public.queue_item DROP CONSTRAINT queue_item_queue_id_fkey;
       public          bwilliam    false    3946    256    254                    2606    84927 .   role_permissions role_permissions_role_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id);
 X   ALTER TABLE ONLY public.role_permissions DROP CONSTRAINT role_permissions_role_id_fkey;
       public          bwilliam    false    217    216    3854         �           2606    85618 6   sent_notifications sent_notifications_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sent_notifications
    ADD CONSTRAINT sent_notifications_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.notification_templates(template_id);
 `   ALTER TABLE ONLY public.sent_notifications DROP CONSTRAINT sent_notifications_template_id_fkey;
       public          bwilliam    false    233    232    3896         �           2606    85570 D   service_feedback_settings service_feedback_settings_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);
 n   ALTER TABLE ONLY public.service_feedback_settings DROP CONSTRAINT service_feedback_settings_template_id_fkey;
       public          bwilliam    false    231    227    3884         �           2606    86179 6   service_form_mapping service_form_mapping_form_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id) ON DELETE CASCADE;
 `   ALTER TABLE ONLY public.service_form_mapping DROP CONSTRAINT service_form_mapping_form_id_fkey;
       public          bwilliam    false    261    3954    259         �           2606    86174 9   service_form_mapping service_form_mapping_service_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id) ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.service_form_mapping DROP CONSTRAINT service_form_mapping_service_id_fkey;
       public          bwilliam    false    241    261    3914         �           2606    85805 &   service service_parent_service_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_parent_service_id_fkey FOREIGN KEY (parent_service_id) REFERENCES public.service(service_id);
 P   ALTER TABLE ONLY public.service DROP CONSTRAINT service_parent_service_id_fkey;
       public          bwilliam    false    241    3914    241         ~           2606    84881 !   settings settings_company_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);
 K   ALTER TABLE ONLY public.settings DROP CONSTRAINT settings_company_id_fkey;
       public          bwilliam    false    215    3840    209         |           2606    84839    sms_api sms_api_company_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sms_api
    ADD CONSTRAINT sms_api_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);
 I   ALTER TABLE ONLY public.sms_api DROP CONSTRAINT sms_api_company_id_fkey;
       public          bwilliam    false    213    209    3840         {           2606    84824 '   smtp_config smtp_config_company_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.smtp_config
    ADD CONSTRAINT smtp_config_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);
 Q   ALTER TABLE ONLY public.smtp_config DROP CONSTRAINT smtp_config_company_id_fkey;
       public          bwilliam    false    212    209    3840         �           2606    85500 @   survey_question_answers survey_question_answers_question_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_question_answers
    ADD CONSTRAINT survey_question_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id);
 j   ALTER TABLE ONLY public.survey_question_answers DROP CONSTRAINT survey_question_answers_question_id_fkey;
       public          bwilliam    false    228    3886    229         �           2606    85485 2   survey_questions survey_questions_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);
 \   ALTER TABLE ONLY public.survey_questions DROP CONSTRAINT survey_questions_template_id_fkey;
       public          bwilliam    false    3884    227    228         �           2606    85519 0   survey_responses survey_responses_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 Z   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_branch_id_fkey;
       public          bwilliam    false    210    230    3842         �           2606    85534 1   survey_responses survey_responses_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 [   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_counter_id_fkey;
       public          bwilliam    false    219    3868    230         �           2606    85524 2   survey_responses survey_responses_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);
 \   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_customer_id_fkey;
       public          bwilliam    false    226    3882    230         �           2606    85544 3   survey_responses survey_responses_dispenser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_dispenser_id_fkey FOREIGN KEY (dispenser_id) REFERENCES public.dispenser(dispenser_id);
 ]   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_dispenser_id_fkey;
       public          bwilliam    false    230    214    3850         �           2606    85549 2   survey_responses survey_responses_question_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id);
 \   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_question_id_fkey;
       public          bwilliam    false    228    230    3886         �           2606    85514 2   survey_responses survey_responses_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);
 \   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_template_id_fkey;
       public          bwilliam    false    227    3884    230         �           2606    85529 .   survey_responses survey_responses_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 X   ALTER TABLE ONLY public.survey_responses DROP CONSTRAINT survey_responses_user_id_fkey;
       public          bwilliam    false    218    230    3864         �           2606    85333 3   ticket_action_log ticket_action_log_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 ]   ALTER TABLE ONLY public.ticket_action_log DROP CONSTRAINT ticket_action_log_counter_id_fkey;
       public          bwilliam    false    224    3868    219         �           2606    85328 0   ticket_action_log ticket_action_log_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 Z   ALTER TABLE ONLY public.ticket_action_log DROP CONSTRAINT ticket_action_log_user_id_fkey;
       public          bwilliam    false    3864    218    224         �           2606    85843 ;   ticket_assignments ticket_assignments_assigned_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_assigned_user_id_fkey FOREIGN KEY (assigned_user_id) REFERENCES public.users(user_id);
 e   ALTER TABLE ONLY public.ticket_assignments DROP CONSTRAINT ticket_assignments_assigned_user_id_fkey;
       public          bwilliam    false    243    218    3864         �           2606    85838 4   ticket_assignments ticket_assignments_ticket_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id) ON DELETE CASCADE;
 ^   ALTER TABLE ONLY public.ticket_assignments DROP CONSTRAINT ticket_assignments_ticket_id_fkey;
       public          bwilliam    false    242    243    3916         �           2606    85825    ticket ticket_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 F   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_branch_id_fkey;
       public          bwilliam    false    210    242    3842         �           2606    85213 -   ticket_process ticket_process_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 W   ALTER TABLE ONLY public.ticket_process DROP CONSTRAINT ticket_process_counter_id_fkey;
       public          bwilliam    false    221    3868    219         �           2606    85208 5   ticket_process ticket_process_service_process_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_service_process_id_fkey FOREIGN KEY (service_process_id) REFERENCES public.service_process(service_process_id);
 _   ALTER TABLE ONLY public.ticket_process DROP CONSTRAINT ticket_process_service_process_id_fkey;
       public          bwilliam    false    3870    220    221         �           2606    85915 B   ticket_workflow_history ticket_workflow_history_from_stage_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_from_stage_id_fkey FOREIGN KEY (from_stage_id) REFERENCES public.workflow_stages(stage_id);
 l   ALTER TABLE ONLY public.ticket_workflow_history DROP CONSTRAINT ticket_workflow_history_from_stage_id_fkey;
       public          bwilliam    false    3920    244    246         �           2606    85910 >   ticket_workflow_history ticket_workflow_history_ticket_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id);
 h   ALTER TABLE ONLY public.ticket_workflow_history DROP CONSTRAINT ticket_workflow_history_ticket_id_fkey;
       public          bwilliam    false    246    242    3916         �           2606    85920 @   ticket_workflow_history ticket_workflow_history_to_stage_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_to_stage_id_fkey FOREIGN KEY (to_stage_id) REFERENCES public.workflow_stages(stage_id);
 j   ALTER TABLE ONLY public.ticket_workflow_history DROP CONSTRAINT ticket_workflow_history_to_stage_id_fkey;
       public          bwilliam    false    244    246    3920         �           2606    85925 B   ticket_workflow_history ticket_workflow_history_transition_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_transition_id_fkey FOREIGN KEY (transition_id) REFERENCES public.workflow_transitions(transition_id);
 l   ALTER TABLE ONLY public.ticket_workflow_history DROP CONSTRAINT ticket_workflow_history_transition_id_fkey;
       public          bwilliam    false    246    245    3922         �           2606    85246 &   user_branch user_branch_branch_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);
 P   ALTER TABLE ONLY public.user_branch DROP CONSTRAINT user_branch_branch_id_fkey;
       public          bwilliam    false    3842    210    222         �           2606    85241 $   user_branch user_branch_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 N   ALTER TABLE ONLY public.user_branch DROP CONSTRAINT user_branch_user_id_fkey;
       public          bwilliam    false    3864    222    218         �           2606    85262 )   user_counter user_counter_counter_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);
 S   ALTER TABLE ONLY public.user_counter DROP CONSTRAINT user_counter_counter_id_fkey;
       public          bwilliam    false    219    223    3868         �           2606    85257 &   user_counter user_counter_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 P   ALTER TABLE ONLY public.user_counter DROP CONSTRAINT user_counter_user_id_fkey;
       public          bwilliam    false    223    3864    218         �           2606    85663 @   voice_notification_logs voice_notification_logs_template_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.voice_notification_logs
    ADD CONSTRAINT voice_notification_logs_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.voice_notification_templates(template_id);
 j   ALTER TABLE ONLY public.voice_notification_logs DROP CONSTRAINT voice_notification_logs_template_id_fkey;
       public          bwilliam    false    234    235    3900         �           2606    85893 <   workflow_transitions workflow_transitions_from_stage_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_stage_id_fkey FOREIGN KEY (from_stage_id) REFERENCES public.workflow_stages(stage_id);
 f   ALTER TABLE ONLY public.workflow_transitions DROP CONSTRAINT workflow_transitions_from_stage_id_fkey;
       public          bwilliam    false    3920    245    244         �           2606    85898 :   workflow_transitions workflow_transitions_to_stage_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_stage_id_fkey FOREIGN KEY (to_stage_id) REFERENCES public.workflow_stages(stage_id);
 d   ALTER TABLE ONLY public.workflow_transitions DROP CONSTRAINT workflow_transitions_to_stage_id_fkey;
       public          bwilliam    false    3920    244    245                                                                                                                                                                                                               4158.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4157.dat                                                                                            0000600 0004000 0002000 00000000432 14620670407 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        2c8d24d6-fd4d-4df6-b120-57d727a9bf26	\N	Labone	0043	auto	05:00:00	French	local	t	t	t	2024-05-09 15:26:15.267324	2024-05-09 15:19:22	\N
867b0bda-8fce-424f-b90b-e817b655b79e	\N	Lapaz	0043	auto	04:00:00	English	local	t	t	t	2024-05-13 14:19:06.026578	2024-05-13 14:19:06.026578	\N
\.


                                                                                                                                                                                                                                      4156.dat                                                                                            0000600 0004000 0002000 00000000220 14620670407 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        3922b164-0b34-4f4e-83d9-2b65c674a6be	CALBank PLC	Accra-Aca	026933258	caltesting@bank.com	2024-05-09 13:08:36.811794	2024-05-09 13:15:43	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                4166.dat                                                                                            0000600 0004000 0002000 00000000415 14620670407 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        74e68aa0-d9ca-4d96-9ac6-17c3ca4262a6	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	Counter 1	t	\N	2024-05-09 15:55:21.256019+00	2024-05-09 15:32:53+00
e988b77b-acd0-498a-91bf-b576c5e82f3e	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	Counter 2	t	\N	2024-05-09 15:55:21.256019+00	\N
\.


                                                                                                                                                                                                                                                   4205.dat                                                                                            0000600 0004000 0002000 00000000224 14620670407 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        c2e3aef6-28c7-4a06-9622-8aa9f1294b52	74e68aa0-d9ca-4d96-9ac6-17c3ca4262a6	a860f12e-d3d4-4a1e-89cd-a5158293d292	2024-05-14 13:26:57.537096+00	t
\.


                                                                                                                                                                                                                                                                                                                                                                            4173.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4187.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4198.dat                                                                                            0000600 0004000 0002000 00000001042 14620670407 0014262 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        efb98360-5d51-454e-ae5f-e14f5d66054d	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	Calvary	dispenser	number	94JA94EY	U1YX7-23Z50-1BY60-5140A-2EE2F-D12BA	2024-05-09 00:00:00	2024-05-09 00:00:00	t	t	t	f	\N	\N	\N	\N	\N	t	2024-05-11 14:26:58.434452+00	2024-05-11 15:24:28+00	\N	activated	2024-05-11 15:24:28+00
3033ec27-bb47-40a2-a1df-4c395354914b	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	Calvary Tv	display	1	31UQ44ZJ	\N	2024-05-09 00:00:00	2024-05-09 00:00:00	t	t	t	f	\N	\N	\N	\N	\N	t	2024-05-12 12:53:13.78123+00	2024-05-12 12:53:13.78123+00	\N	active	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              4161.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4186.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4185.dat                                                                                            0000600 0004000 0002000 00000000232 14620670407 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        38f10591-b9dd-4c44-b0eb-70ef58d099da	image template	\N	image	yellow	2024-05-12 02:51:45.955483+00	2024-05-12 05:33:00+00	\N	\N	dispenser	hello world
\.


                                                                                                                                                                                                                                                                                                                                                                      4184.dat                                                                                            0000600 0004000 0002000 00000000524 14620670407 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        25d2c8e5-6538-4322-89a6-fa290c754dd7	efb98360-5d51-454e-ae5f-e14f5d66054d	38f10591-b9dd-4c44-b0eb-70ef58d099da	2024-05-12 05:05:03.556434+00	2024-05-12 05:26:30+00
02ba8c45-6da8-4303-9063-f7836349f9c9	3033ec27-bb47-40a2-a1df-4c395354914b	38f10591-b9dd-4c44-b0eb-70ef58d099da	2024-05-12 12:54:47.059349+00	2024-05-12 12:54:47.059349+00
\.


                                                                                                                                                                            4183.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4196.dat                                                                                            0000600 0004000 0002000 00000000005 14620670407 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4199.dat                                                                                            0000600 0004000 0002000 00000000565 14620670407 0014274 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        9b8f73f5-95c2-46ec-aa8e-31a1f99bc527	dispenser	./uploads/images/dispenser/	WhatsApp Image 2024-05-08 at 11.14.12.jpeg	image/jpeg	2024-05-12 02:51:45.958756+00	dispenser_template_setup	\N	\N
0ca08c2c-e87a-4537-a6dc-f526444cc36e	dispenser	./uploads/images/dispenser/	2409_1948550_1639037301393.jpg	image/jpeg	2024-05-12 02:51:45.963606+00	dispenser_template_setup	\N	\N
\.


                                                                                                                                           4207.dat                                                                                            0000600 0004000 0002000 00000001107 14620670410 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        41f5004a-c491-4da6-a4c4-a162df738a26	e507169d-c010-4bbf-b5c9-ab9208f17be0	Fullname	text	f	\N	f	\N	3	\N	2024-05-13 11:37:55.236925+00	\N	\N
6a8bb2eb-5e1c-4b54-a6a2-393f18796c34	e507169d-c010-4bbf-b5c9-ab9208f17be0	Email	text	t	\N	f	\N	4	\N	2024-05-13 11:37:55.238208+00	\N	\N
b3bfccdf-f8ec-4d18-a9e8-547a36d0ccb8	e507169d-c010-4bbf-b5c9-ab9208f17be0	Comments	textarea	f	\N	f	\N	2	\N	2024-05-13 11:37:55.239388+00	\N	\N
938a671f-bb61-437d-99d9-41bf785e1663	e507169d-c010-4bbf-b5c9-ab9208f17be0	Amounts	number	t	\N	f	\N	1	\N	2024-05-13 11:37:55.220436+00	2024-05-13 11:38:34+00	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                         4206.dat                                                                                            0000600 0004000 0002000 00000000375 14620670410 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        e507169d-c010-4bbf-b5c9-ab9208f17be0	Momo Transfer	verification_endpoint.com	\N	2024-05-13 11:34:57.452319+00	\N	f
7c7ad0a2-f9a0-4a2c-947c-9225b4deb518	Withdrawal	verification_endpoints.com	\N	2024-05-13 11:34:42.951359+00	2024-05-13 11:28:40+00	f
\.


                                                                                                                                                                                                                                                                   4200.dat                                                                                            0000600 0004000 0002000 00000000235 14620670410 0014237 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        021113e2-43cc-4763-b90c-847073aa493b	EUR	2024-05-10	14.000000	38f10591-b9dd-4c44-b0eb-70ef58d099da	2024-05-12 08:32:50.821723+00	2024-05-12 08:31:32+00
\.


                                                                                                                                                                                                                                                                                                                                                                   4197.dat                                                                                            0000600 0004000 0002000 00000000622 14620670410 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        fe186c5f-d159-4785-8191-2b34da086a0f	image	9b8f73f5-95c2-46ec-aa8e-31a1f99bc527.jpeg	dispenser	\N	\N	38f10591-b9dd-4c44-b0eb-70ef58d099da	\N	2024-05-12 02:51:45.960458+00	2024-05-12 02:51:45.960458+00
5562c53c-5eec-4f65-921a-d5b009da7a62	image	0ca08c2c-e87a-4537-a6dc-f526444cc36e.jpg	dispenser	\N	\N	38f10591-b9dd-4c44-b0eb-70ef58d099da	\N	2024-05-12 02:51:45.9649+00	2024-05-12 02:51:45.9649+00
\.


                                                                                                              4179.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4194.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4201.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014233 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4203.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014235 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4204.dat                                                                                            0000600 0004000 0002000 00000032421 14620670410 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        c3edd32c-ca11-4d36-a982-b1031a8f391f	Generated	0f582c60-90dd-479b-a4ff-0e99de45b29d	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:01:00.105165+00
9a11ad3b-0d2d-4ec4-83fa-2fc083b59c2a	Generated	5872b088-f4ce-44f7-8236-4f50dc0f401f	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:01:01.84537+00
4871b47d-96b1-4b5b-acbf-17c852141a80	Generated	6f0c37d5-6924-4be9-aa31-a85a89f417ca	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:01:03.336848+00
4d6ab418-fedf-4903-9f39-547bb10b98f5	Generated	ccfc616f-d44d-4235-8893-ae8690263896	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:02:28.463002+00
e78a41b8-2dc3-4733-a500-a8d9f71d4f62	Generated	3bb6d724-8355-4ac5-855a-216cdf939ebe	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:02:29.954879+00
5fc7b913-d1ee-410e-aeb0-ed2bcfec4308	Generated	84dc648f-7036-4d61-b5cb-35a2f4dbf9d7	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:04:34.126001+00
01523cbb-6441-4c1a-8f41-50c511ff5595	Generated	b21a25a3-24fd-4a48-9d09-acb4cdfc8d8f	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:04:49.948626+00
ac0866af-ac55-4684-b240-4edb802057a1	Generated	ba0b368f-5c86-4b35-8129-48c84cb972f1	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:04:51.347163+00
1a6617e9-2546-47bd-b243-c4a35a5cb872	Generated	9486493e-640c-4b59-8053-9f4edfe46e8e	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:05:07.853699+00
5ecc59a9-dc1e-4d4a-9240-b11eaa55eef6	Generated	27c7070a-2341-42d3-860b-72964f7cf618	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:05:34.372346+00
70b3a572-04a2-4a24-a0f5-f7695286002e	Generated	7414b9d4-0557-4b34-9a9d-d47e4b56896d	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:09:37.477689+00
a0a4280c-76ea-49e3-9838-ed570bc1ca72	Generated	149b63e9-a544-4e04-acc5-e28b6e7646ac	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:09:39.892889+00
754483ce-7507-4ba3-b65b-d7924ee9a9fc	Generated	f6742f26-9a6f-494a-9160-cfc3f85931b7	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:09:41.224122+00
73e1d04a-ad57-48f7-bbba-382beb83a1fa	Generated	472d2df9-d754-4c28-a0d3-710d4d1cec72	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:10:00.293735+00
5340496d-a44d-4055-8a54-89cd2463e277	Generated	5b94c893-8809-4762-b8b4-bff867d3a009	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:13:44.284926+00
e370bdcb-a221-4670-8079-52479e7e9ecf	Generated	4aea47ba-20ec-4a19-aeb4-ae2f4fdd8333	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:21:53.991769+00
93ab8b79-2cc3-4a76-b9f5-81b4dcf22442	Generated	3440c997-6e24-4099-bc3c-839778d284c5	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:21:55.946321+00
4620d265-0f81-42ca-8e1c-adde55458f2b	Generated	a539a8a3-3760-481b-ab22-e141e9cb218c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:22:25.984953+00
3514d991-7dbd-4e63-a7d3-d01eb3d38e2f	Generated	02a69589-3c82-448b-8dc6-2c817b76d5a2	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:26:15.461211+00
4b9a04b8-c4a6-4be3-a684-b0f39d00bd81	Generated	eaeb6e66-c871-4e20-aace-efab0eef46af	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:26:16.955611+00
da52f9d5-390e-4a16-b89f-bbfc74c74a33	Generated	c2f455f3-33d5-40b4-80e6-5cda6ad1bd1c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:26:33.87933+00
1528318a-b783-455a-aa84-eb4fc3353b21	Generated	93f2992b-b4cf-40fb-bb18-b54c24f05d8f	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:30:19.98612+00
f5f36d5f-fef0-4a8d-867f-7484358a4d2e	Generated	a0a0356c-c089-49c2-a7d0-0b428977decd	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:30:21.322143+00
87195863-5655-42ab-b325-0c75ff6737a5	Generated	d38622f8-fce3-41be-a57a-fbd5a9f0214d	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 17:30:39.146624+00
e18d45d7-d383-4c99-aff4-43f5a63dafa3	Generated	80a8360c-fe66-4205-b009-42bc9818fc13	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:27:33.892517+00
87d5522b-b546-4f9a-9e65-bc5bd240ad97	Generated	c1300e96-b96d-4553-9779-e255fe2a411c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:27:36.274061+00
83b2b4e9-5b35-473b-81f6-8a9ed959aa8c	Generated	ceaa7b61-2d3f-4ea4-b1a5-132cec241da4	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:27:59.027724+00
82a62288-bdd2-4fda-8095-a430fff7e31a	Generated	06be7d6c-7c4a-4f86-9bd1-1a9a4ee42007	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:34:47.027528+00
eb93f3d1-8e0f-41d2-9957-29668348123e	Generated	3296fa6c-1818-49e3-9daa-77460f771ce2	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:34:48.555416+00
96c1b9b0-45e9-4e68-9712-5f07c08cbd9f	Generated	bf6e8810-94d4-44fa-9004-806df34f0321	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:35:14.417323+00
ebf0ac31-63a6-465b-afbc-a8b9d8d8000b	Generated	bd36407a-72f3-469d-9e9b-10a32a4b20a2	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:40:26.201725+00
ff7846df-d6cc-4275-8a63-677b506f07bb	Generated	256194cc-1d51-4011-a488-7e10031b5b9d	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:40:27.752026+00
27caa0d2-5265-4cf1-b56f-77249ae01dc1	Generated	3bbf91a2-4398-4150-82f7-771e372081fc	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:43:18.534343+00
f0699476-787f-49a9-9ddf-c6242cba16d4	Generated	78d7562f-5586-4fec-9286-e6cb786c7d3c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:43:20.008448+00
3472ffed-5b50-443c-a495-3b17b03b8b8c	Generated	c55ee1f0-7072-4595-9e4c-c12d96773d25	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:43:41.38328+00
6cc26b83-2a09-48d7-8514-a5bcc78cfa98	Generated	5563c50f-ac49-478e-a93a-35e70e411e76	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:43:42.385074+00
96e56445-0d09-4f7d-8b44-5e2a2ed7f1e7	Generated	0b0a2fb7-7759-4d68-aed3-d446643efdb6	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:00.754795+00
af171080-9677-48b0-a3d9-93ac4d52f18a	Generated	755d76b9-7652-4a7c-89e3-45eed2180742	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:01.901107+00
f1f08b0e-3851-44e9-b657-008f8c6f53c7	Generated	d1c7d3e2-2e10-4bfc-87cb-56e7e5bf40f4	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:20.884182+00
1d11a644-3a5b-465c-aed7-c97fd0469c3b	Generated	43564092-3d6d-4dda-85e4-e71c26fc9a61	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:21.749409+00
6e2e4ec7-0240-4bd4-bc46-4f8c29aeab4b	Generated	82d63808-41ac-40a2-a9bf-52df53d5de95	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:42.541753+00
3c91eb3c-ab0a-4189-9aaf-2df9bc4d1bc9	Generated	87c41a2c-7afb-4b3b-b3c5-599276f194fb	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:44:43.39385+00
7e35cb77-3457-4f09-88f0-4efcb2f3b29e	Generated	9fc653c8-0131-4a41-9645-6f9a3420d7d2	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:45:54.098456+00
fae00d1c-0eb9-4090-9902-f04310374d13	Generated	de017cac-a75d-4fb4-8a18-ac9dabbe13c9	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:45:55.110049+00
0736acc2-38d0-45eb-aa31-a9c7501a6d6d	Generated	b359d3a2-47ef-4e8e-8a00-c62e4b6d6357	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:45:56.426726+00
f3834f98-426d-4641-a4d0-07ec85269440	Generated	a6841dc0-27b3-4cb7-ad3b-56c3694b1cd7	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:47:55.241623+00
708b4e31-3c78-4aa5-9b32-2c8e39ab76d1	Generated	4e1ba885-b20f-439c-82cc-0f09f80fac32	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:47:56.480149+00
ceff64d4-d03c-4aa4-9fe0-4434fad5055d	Generated	23005100-1935-4478-8e61-f6b5287acad9	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:47:57.827465+00
685b9941-0807-41ae-9761-26f44715a46e	Generated	72adc6de-dc06-4a39-8158-007d8f6bd12f	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:49:07.139409+00
018a08f6-1cca-4b39-bec9-c0c1d5966b7b	Generated	e1557168-ba42-495f-bfa7-3ce76be09334	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:49:08.093079+00
8082f577-ecf9-4cd3-9b8f-49ba45a8b45a	Generated	00d295cc-8eeb-4da0-9057-2f5e42b292db	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:49:09.272075+00
d36ec4df-186c-4c03-b93e-6ffc77e329a6	Generated	a402f5ae-e43a-4e99-9c98-49baee247200	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:51:05.926503+00
823d4bd0-4f2a-4e6c-9158-c173a7c30382	Generated	19bbe589-5607-4603-95ad-86cae0dfbe57	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:51:06.826684+00
267b99e6-2f54-49fa-b554-4ab55a3482c5	Generated	141bc9c5-610e-49be-bbee-8bfcca862351	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:51:07.73846+00
c3616aa8-46f2-4907-bdac-75d503abe8ea	Generated	ba8a879e-0fa5-468f-8319-ceb4a83b7025	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:51:08.646839+00
642552a2-2e6a-4d66-94ea-d8e53870eb3f	Generated	214472b5-2dc7-459b-8273-9bfba9cbfed9	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:53:42.776411+00
0ae42c0f-7df6-4864-bd9b-97cde60afd72	Generated	321116d8-b5b6-4ac0-a96e-6f25f83e406b	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:53:43.979658+00
2970e7b7-d0da-4b04-ae6b-eb399ec6c010	Generated	9ba49c5d-45ed-4bb5-82f4-e39665bd8264	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:53:44.967177+00
276291b0-8d13-4588-9c41-db8abb1d2cbc	Generated	0a12eaea-f70f-466e-9833-7947a5fe5332	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:53:45.795961+00
f2acddda-7f9a-4cfc-9c8d-632075dc2fca	Generated	de84b03f-db6c-4fed-b158-81c0cf57cf37	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:57:51.675106+00
8d93031f-69a1-4dbb-97c7-abd75fbbde78	Generated	96134f0b-ca45-47ed-b178-9c7fbbdc5fb7	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:57:52.582466+00
1559609e-f70e-4983-9ab9-ee8e4b8c8c41	Generated	5ddb9e23-3c93-4bc3-87d8-2ab7290469f6	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:57:53.581814+00
51ca8f2c-27f3-4df3-a419-19b0c0c176b7	Generated	d150ece9-61f8-46b8-8194-bdf1727fe9b9	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:57:54.371421+00
e46f9aa8-4059-4bda-927b-5876dfa3ac6c	Generated	02809459-8504-4a11-bab5-65b2c06d605c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:59:52.129376+00
bdd9a5c0-6cdb-43a9-ac2d-79e17a7f650a	Generated	a09b5627-8ea6-4091-a1f1-e9d4a7d27417	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:59:53.665342+00
205a6df6-cb9d-4494-bbc7-6f25317c25c0	Generated	ad3b13bc-ee81-4d0d-bcf4-97ef31a39916	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 20:59:54.565263+00
697bb0d7-73c4-4467-a95a-9260d2d94e2a	Generated	396fdcd7-6f8d-49d2-8b52-a0d1bc7b3696	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:01:11.973465+00
6f22daed-dfa1-464e-baf4-f96bcbcd940a	Generated	119819bf-f565-4610-b695-05fcb04f6092	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:01:13.136165+00
ab63cc84-e383-44d3-beac-0eb02e6520b9	Generated	e2b14217-b6a6-4f2a-9160-476b3949e65d	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:01:57.874034+00
7047c174-d2e4-492e-8f40-0bd0038d50df	Generated	282d26c1-b8af-4526-9ad5-abc9e1cfcee8	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:01:59.5903+00
bb4bb321-588f-43c5-a202-964ab52fdb22	Generated	e7d5768d-e622-4753-bec2-89d5e562c37c	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:02:00.644442+00
f8529a6a-6648-470b-8086-1799329360c8	Generated	add06233-9d40-49b6-8362-8799534bc122	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:02:01.540783+00
f92c1fc9-ed18-4dc1-b935-0029974f061f	Generated	4532b347-bff2-45fb-84cc-2fd0ffdbb729	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:02:39.02772+00
a52e57f8-4ba1-45b8-9fcc-eb7c8214d2a2	Generated	4c6ed7e5-7f20-479d-810b-7bfa56fca018	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:26:29.797213+00
58ee71a8-2691-4054-8cf6-a6d9dc6313c3	Generated	6faa93c4-a391-457f-bba8-1e4a25a81043	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:26:32.667828+00
bf339d99-3769-40b7-ad98-c35ccc51a2e8	Generated	6f1b8a93-bcfd-41f6-8a38-b3b11d9d87b0	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-13 21:35:56.869237+00
8a9a2104-bdcc-49f3-ba19-d3cd7fb23b02	Generated	82d3c51f-f25c-48b7-9b64-c3ffd6b4efd8	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:31:17.285246+00
97fe9af8-d380-42da-a112-7ed69cd9a638	Generated	f29dab3d-0caf-4f7e-b752-e8636cb1e04a	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:42:58.668235+00
38517d36-be3c-4d58-aef7-e1f9ee59367a	Generated	96119dd7-ca72-4697-a773-06404d7d7970	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:43:59.52984+00
ab07955c-b816-46f2-9788-b38c450a5a81	Generated	de19edb3-b0a6-49b0-9f12-25237c589702	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:44:06.342261+00
e3d477b5-4924-4534-8eaf-cf1ae7519d37	Generated	339270a2-43fc-4de7-9ca2-3b72f5b0d577	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:44:22.087912+00
47e3cf9f-df77-47ff-8c4b-a8b1e41d59b7	Generated	ddbd6c8f-e3dc-4826-8f0f-e4073a82e070	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:45:04.727094+00
e79038ba-a9fe-490c-95e3-26dc43b4babc	Generated	c3f746f6-226d-4f46-a9b7-7d65ee2e895e	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:45:48.603204+00
168f8e21-c855-488d-9a11-9093cd88ae5b	Generated	bf00dca5-4cce-4c7f-80bd-6d9889cdbfb9	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:45:50.953706+00
8cbdbb0f-ff76-4520-be53-cf30dbebdfbd	Generated	42c43c96-b2ca-4918-aebe-c05f514da1b4	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 04:45:52.871511+00
4420f463-7d22-4daa-b417-7d4887326f4b	Generated	6fdb2135-0234-48ca-8889-7a112ae9f704	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 05:30:34.810802+00
05807790-c02b-4a83-896f-432490eff5a9	Generated	a6c8a0ff-bed6-496e-b051-7cb3633b20d4	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 05:30:37.712545+00
33b3b612-e2c4-4f86-8b53-23b6bac3ee6f	Generated	a860f12e-d3d4-4a1e-89cd-a5158293d292	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 05:31:09.509844+00
ed17f0bb-7622-472b-9f10-d32bb8cbe4af	Generated	9555c9b9-ec4f-4c00-92cc-7f30b44a8fba	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 13:38:36.335434+00
5643dc4a-86b9-49bb-906b-854f517d9dae	Generated	7faf57fd-231b-421f-b930-24f6b00a47c8	e507169d-c010-4bbf-b5c9-ab9208f17be0	2024-05-14 13:40:06.818887+00
\.


                                                                                                                                                                                                                                               4164.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4163.dat                                                                                            0000600 0004000 0002000 00000000313 14620670410 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        bb2e2e2f-d328-427d-b5e7-37652ff9d2e8	Admin	default role	2024-05-09 14:48:19.101982	t	2024-05-09 13:15:43	t
8b51ae5c-d387-4efc-8e96-f16e699f2e3a	Teller	default role	2024-05-14 06:13:31.066114	t	\N	f
\.


                                                                                                                                                                                                                                                                                                                     4180.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4188.dat                                                                                            0000600 0004000 0002000 00000001577 14620670410 0014270 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        0cc59683-8c3d-46ce-9967-a705da03c28c	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	Withdrawal	Funds Transfer Withdrawal		green	FT Cash	transfer to account	2024-05-09 16:09:10.131	2024-05-09 16:08:48	\N	fa-fatimes	1
35d9ae47-e0f6-4dd4-881d-2bccb9ffdf29	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	\N	School Fees	Fee Payment		yellow	FT Cash	transfer to account	2024-05-10 08:57:48.556215	2024-05-10 08:57:48.556215	\N	fa-fatimes	1
9ba86dba-aa93-4d5d-b427-5ba02f324e05	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	Momo Transfer	Funds Transfer Momo		green	FT Cash	transfer to account	2024-05-09 16:09:10.131	2024-05-09 16:08:48	\N	fa-fatimes	1
b8b8590e-d361-4fb7-b9e0-9adf092e161f	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	\N	Transfer	Funds Transfer		yellow	FT Cash	transfer to account	2024-05-09 16:09:10.131899	2024-05-09 16:08:48	\N	fa-fatimes	1
\.


                                                                                                                                 4178.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4208.dat                                                                                            0000600 0004000 0002000 00000000216 14620670410 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        5d394de6-1382-4563-903c-5092506c6b47	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	\N	2024-05-13 12:02:47+00
\.


                                                                                                                                                                                                                                                                                                                                                                                  4167.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4162.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4160.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014237 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4159.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4176.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4175.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4177.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4174.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4189.dat                                                                                            0000600 0004000 0002000 00000003024 14620670410 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        a6c8a0ff-bed6-496e-b051-7cb3633b20d4	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	HQ002	2024-05-14 05:30:37.712545+00	Closed	0	\N	2024-05-14 05:30:37.712545+00	efb98360-5d51-454e-ae5f-e14f5d66054d	f	f	\N	\N	e507169d-c010-4bbf-b5c9-ab9208f17be0
6fdb2135-0234-48ca-8889-7a112ae9f704	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	HQ001	2024-05-14 05:30:34.810802+00	Closed	0	\N	2024-05-14 05:30:34.810802+00	efb98360-5d51-454e-ae5f-e14f5d66054d	f	f	\N	\N	e507169d-c010-4bbf-b5c9-ab9208f17be0
a860f12e-d3d4-4a1e-89cd-a5158293d292	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	HQ001	2024-05-14 05:31:09.509844+00	Served	0	\N	2024-05-14 05:31:09.509844+00	efb98360-5d51-454e-ae5f-e14f5d66054d	f	f	\N	\N	e507169d-c010-4bbf-b5c9-ab9208f17be0
9555c9b9-ec4f-4c00-92cc-7f30b44a8fba	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	HQ002	2024-05-14 13:38:36.335434+00	Served	0	\N	2024-05-14 13:38:36.335434+00	efb98360-5d51-454e-ae5f-e14f5d66054d	f	f	\N	\N	e507169d-c010-4bbf-b5c9-ab9208f17be0
7faf57fd-231b-421f-b930-24f6b00a47c8	2c8d24d6-fd4d-4df6-b120-57d727a9bf26	b8b8590e-d361-4fb7-b9e0-9adf092e161f	e507169d-c010-4bbf-b5c9-ab9208f17be0	HQ001	2024-05-14 13:40:06.818887+00	Pending	1	\N	2024-05-14 13:40:06.818887+00	efb98360-5d51-454e-ae5f-e14f5d66054d	f	f	\N	\N	e507169d-c010-4bbf-b5c9-ab9208f17be0
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            4171.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4190.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4172.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4168.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4193.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4169.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4170.dat                                                                                            0000600 0004000 0002000 00000000164 14620670410 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        54ac817a-7d55-4c3d-bff2-c07eedf7b448	4f1c2ab4-a0bd-415e-934d-d2b4a0400b29	74e68aa0-d9ca-4d96-9ac6-17c3ca4262a6
\.


                                                                                                                                                                                                                                                                                                                                                                                                            4195.dat                                                                                            0000600 0004000 0002000 00000001305 14620670410 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        6e32bb93-aeae-48b0-8d44-44641cd6c5cc	c9741c1e-6efe-4e89-a372-0287e4d31eae	bb2e2e2f-d328-427d-b5e7-37652ff9d2e8	2024-05-09 15:06:15.608297+00
d56c12cf-0f9c-48e4-8e69-8afc6f76ac1c	4f1c2ab4-a0bd-415e-934d-d2b4a0400b29	8b51ae5c-d387-4efc-8e96-f16e699f2e3a	2024-05-14 06:22:59.345593+00
5144ebba-07d3-462c-ba7b-3fd5fee26f52	4e6426e9-189c-4c8c-aa71-3d2f0766673e	8b51ae5c-d387-4efc-8e96-f16e699f2e3a	2024-05-14 06:23:20.904352+00
482ffd30-ce26-426d-a6e8-7631fe8be7a4	24816e2e-2f27-43db-954e-593e2c686be6	8b51ae5c-d387-4efc-8e96-f16e699f2e3a	2024-05-14 06:23:48.043155+00
2a3bf002-56d2-4b6b-91fe-11d172209e3b	773cb7da-54ca-4b87-9867-2a0c47c3a4bd	8b51ae5c-d387-4efc-8e96-f16e699f2e3a	2024-05-14 06:24:30.16505+00
\.


                                                                                                                                                                                                                                                                                                                           4165.dat                                                                                            0000600 0004000 0002000 00000002331 14620670410 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        c9741c1e-6efe-4e89-a372-0287e4d31eae	gashie	william@calbank.net	$2b$10$PGlc6QvUkr13khUtj3dRT.g3btJyaOWfDr/dKnB6Di8u7u1hBWjdK	Rico	Williams	\N	\N	\N	2024-05-09 15:06:15.601912+00	\N	t	t	t	\N	\N	\N	t	\N	f	\N	t	\N
4e6426e9-189c-4c8c-aa71-3d2f0766673e	teller_two	teller_two@calbank.net	$2b$10$5j5Y1snbBypXu5GB5c7B6el4uEYWAi7OitbMsANHtp8lVbVFt6vNe	Teller	Two	\N	\N	\N	2024-05-14 06:23:20.900576+00	\N	t	f	t	\N	\N	\N	t	\N	f	\N	t	2c8d24d6-fd4d-4df6-b120-57d727a9bf26
24816e2e-2f27-43db-954e-593e2c686be6	teller_three	teller_three@calbank.net	$2b$10$6374peKUs9FuBRSHGuWJrul/EHD51ASDOPbb.f1F/53kuaoQrVMnC	Teller	Three	\N	\N	\N	2024-05-14 06:23:48.039203+00	\N	t	f	t	\N	\N	\N	t	\N	f	\N	t	867b0bda-8fce-424f-b90b-e817b655b79e
773cb7da-54ca-4b87-9867-2a0c47c3a4bd	teller_four	teller_four@calbank.net	$2b$10$g/JBhNnaGPLtl7BCxQ11S.FoYW93ixJujnSoEw/dtqQPLHlc55Z/K	Teller	Four	\N	\N	\N	2024-05-14 06:24:30.162595+00	\N	t	f	t	\N	\N	\N	f	\N	f	\N	t	867b0bda-8fce-424f-b90b-e817b655b79e
4f1c2ab4-a0bd-415e-934d-d2b4a0400b29	teller_one	teller_one@calbank.net	$2b$10$MPsEHXe7F7UE3j3qTsZ.6OHAMw.NEgLm.vJ0c8xBePnb4/k9lqeVS	Teller	One	\N	\N	\N	2024-05-14 06:22:59.341359+00	2024-05-14 12:18:29+00	t	f	t	\N	\N	\N	t	\N	f	\N	t	2c8d24d6-fd4d-4df6-b120-57d727a9bf26
\.


                                                                                                                                                                                                                                                                                                       4182.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4181.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4191.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4192.dat                                                                                            0000600 0004000 0002000 00000000005 14620670410 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           restore.sql                                                                                         0000600 0004000 0002000 00000271112 14620670410 0015370 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 14.10 (Homebrew)
-- Dumped by pg_dump version 15.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE qms;
--
-- Name: qms; Type: DATABASE; Schema: -; Owner: bwilliam
--

CREATE DATABASE qms WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';


ALTER DATABASE qms OWNER TO bwilliam;

\connect qms

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: bwilliam
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO bwilliam;

--
-- Name: generate_ticket(character varying, uuid, uuid, uuid, character varying, uuid, uuid); Type: FUNCTION; Schema: public; Owner: bwilliam
--

CREATE FUNCTION public.generate_ticket(p_branch_acronym character varying, p_branch_id uuid, p_service_id uuid, p_customer_id uuid, p_status character varying, p_dispenser_id uuid, p_form_id uuid) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.generate_ticket(p_branch_acronym character varying, p_branch_id uuid, p_service_id uuid, p_customer_id uuid, p_status character varying, p_dispenser_id uuid, p_form_id uuid) OWNER TO bwilliam;

--
-- Name: update_ticket_position(); Type: FUNCTION; Schema: public; Owner: bwilliam
--

CREATE FUNCTION public.update_ticket_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

    -- Update the position of the served or closed ticket to 0
    IF NEW.status IN ('Closed', 'Served') THEN
        UPDATE ticket
        SET queue_position = 0
        WHERE ticket_id = NEW.ticket_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_ticket_position() OWNER TO bwilliam;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_directory; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.active_directory (
    ad_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    domain_name character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.active_directory OWNER TO bwilliam;

--
-- Name: branch; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.branch (
    branch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    name character varying(255) NOT NULL,
    portal_code character varying(20),
    closing_type character varying(50),
    closing_time time without time zone,
    default_language character varying(50),
    time_zone character varying(50),
    enable_appointment boolean DEFAULT false,
    smart_ticket boolean DEFAULT false,
    status boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.branch OWNER TO bwilliam;

--
-- Name: company; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.company (
    company_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    address character varying(255),
    phone character varying(20),
    email character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.company OWNER TO bwilliam;

--
-- Name: counter; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.counter (
    counter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    name character varying(255) NOT NULL,
    status boolean DEFAULT true NOT NULL,
    service_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);


ALTER TABLE public.counter OWNER TO bwilliam;

--
-- Name: counter_ticket; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.counter_ticket (
    counter_ticket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    counter_id uuid,
    ticket_id uuid,
    assigned_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    served boolean DEFAULT false
);


ALTER TABLE public.counter_ticket OWNER TO bwilliam;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.customers (
    customer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    email character varying(255),
    phone_number character varying(20),
    address text,
    city character varying(100),
    state character varying(100),
    country character varying(100),
    postal_code character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customers OWNER TO bwilliam;

--
-- Name: device_logs; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.device_logs (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_name character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    location character varying(255),
    ip_address character varying(50) NOT NULL,
    last_connection timestamp with time zone,
    connection_status boolean,
    connection_log jsonb[],
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.device_logs OWNER TO bwilliam;

--
-- Name: devices; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    device_name character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    ip_address character varying(50) NOT NULL,
    authentication_code character varying(50) NOT NULL,
    license_key character varying(255),
    validity_starts timestamp without time zone,
    validity_ends timestamp without time zone,
    show_appointment_button boolean DEFAULT false,
    show_authentication_button boolean DEFAULT false,
    show_estimated_waiting_time boolean DEFAULT false,
    show_number_of_waiting_clients boolean DEFAULT false,
    num_services_on_one_ticket integer,
    idle_time_before_returning_to_main_screen integer,
    ticket_layout text,
    special_service text,
    agent_info jsonb,
    is_activated boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    activation_status character varying(50),
    activated_at timestamp with time zone
);


ALTER TABLE public.devices OWNER TO bwilliam;

--
-- Name: dispenser; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.dispenser (
    dispenser_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    name character varying(255) NOT NULL,
    language character varying(50),
    show_appointment_button boolean DEFAULT false,
    show_authentication_button boolean DEFAULT false,
    show_estimated_waiting_time boolean DEFAULT false,
    show_number_of_waiting_clients boolean DEFAULT false,
    num_services_on_one_ticket integer,
    idle_time_before_returning_to_main_screen integer,
    ticket_layout text,
    validity_starts timestamp without time zone,
    validity_ends timestamp without time zone,
    special_service text,
    agent_name character varying(255),
    agent_ip character varying(50),
    authentication_key character varying(255),
    status boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.dispenser OWNER TO bwilliam;

--
-- Name: dispenser_device_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.dispenser_device_templates (
    device_template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.dispenser_device_templates OWNER TO bwilliam;

--
-- Name: dispenser_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.dispenser_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    branch_id uuid,
    template_type character varying(50) NOT NULL,
    background_color character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    background_video character varying(500),
    background_image character varying(500),
    assigned_to character varying(50),
    news_scroll text
);


ALTER TABLE public.dispenser_templates OWNER TO bwilliam;

--
-- Name: display_device_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.display_device_templates (
    device_template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.display_device_templates OWNER TO bwilliam;

--
-- Name: display_devices; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.display_devices (
    device_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    device_name character varying(255) NOT NULL,
    ip_address character varying(50) NOT NULL,
    authentication_code character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.display_devices OWNER TO bwilliam;

--
-- Name: display_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.display_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    background_image bytea,
    background_color character varying(20),
    split_type character varying(20),
    page_style character varying(50),
    name_on_display_screen boolean,
    need_mobile_screen boolean,
    show_skip_call boolean,
    show_waiting_call boolean,
    skip_closed_call boolean,
    display_screen_tune character varying(255),
    show_queue_number character varying(20),
    show_missed_queue_number character varying(20),
    full_screen_option boolean,
    show_disclaimer_message boolean,
    show_missed_queue_with_marquee boolean,
    template_type character varying(50) NOT NULL,
    content_source_type character varying(50),
    content_endpoint character varying(255),
    content_source character varying(255),
    section_division integer,
    content_configuration jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.display_templates OWNER TO bwilliam;

--
-- Name: file_uploads; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.file_uploads (
    upload_id uuid DEFAULT gen_random_uuid() NOT NULL,
    folder_name character varying(200),
    folder_location character varying(200),
    file_name character varying(500),
    file_type character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    upload_for character varying(100),
    uploaded_by uuid,
    old_file_name character varying(500)
);


ALTER TABLE public.file_uploads OWNER TO bwilliam;

--
-- Name: form_fields; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.form_fields (
    field_id uuid DEFAULT gen_random_uuid() NOT NULL,
    form_id uuid,
    label character varying(255) NOT NULL,
    field_type character varying(50) NOT NULL,
    is_required boolean DEFAULT false,
    options_endpoint character varying(255),
    is_verified boolean DEFAULT false,
    verification_endpoint character varying(255),
    order_index integer NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    options jsonb
);


ALTER TABLE public.form_fields OWNER TO bwilliam;

--
-- Name: forms; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.forms (
    form_id uuid DEFAULT gen_random_uuid() NOT NULL,
    form_name character varying(255) NOT NULL,
    verification_endpoint character varying(255),
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    needs_verification boolean DEFAULT false
);


ALTER TABLE public.forms OWNER TO bwilliam;

--
-- Name: fx_rates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.fx_rates (
    rate_id uuid DEFAULT gen_random_uuid() NOT NULL,
    currency_code character varying(3) NOT NULL,
    rate_date date NOT NULL,
    exchange_rate numeric(12,6) NOT NULL,
    template_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fx_rates OWNER TO bwilliam;

--
-- Name: media_content; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.media_content (
    content_id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_type character varying(50) NOT NULL,
    content_url character varying(255) NOT NULL,
    assigned_to character varying(50) NOT NULL,
    assigned_id uuid,
    branch_id uuid,
    dispenser_template_id uuid,
    display_template_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.media_content OWNER TO bwilliam;

--
-- Name: notification_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.notification_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    template_type character varying(50) NOT NULL,
    subject character varying(255) NOT NULL,
    template_content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notification_templates OWNER TO bwilliam;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.permissions (
    route_path character varying(255) NOT NULL,
    route_method character varying(50) NOT NULL,
    permission_name character varying(255) NOT NULL,
    description text,
    controller_function character varying(100),
    middleware character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.permissions OWNER TO bwilliam;

--
-- Name: queue; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.queue (
    queue_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    service_id uuid,
    is_default boolean DEFAULT true,
    algorithm character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.queue OWNER TO bwilliam;

--
-- Name: queue_item; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.queue_item (
    queue_item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    queue_id uuid,
    ticket_id uuid,
    counter_id uuid,
    "position" integer NOT NULL,
    served boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.queue_item OWNER TO bwilliam;

--
-- Name: queue_item_position_seq; Type: SEQUENCE; Schema: public; Owner: bwilliam
--

CREATE SEQUENCE public.queue_item_position_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.queue_item_position_seq OWNER TO bwilliam;

--
-- Name: queue_item_position_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bwilliam
--

ALTER SEQUENCE public.queue_item_position_seq OWNED BY public.queue_item."position";


--
-- Name: queue_log; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.queue_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    action_type character varying(50),
    ticket_id uuid,
    user_id uuid,
    action_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.queue_log OWNER TO bwilliam;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.role_permissions (
    role_permission_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid,
    permission_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id uuid
);


ALTER TABLE public.role_permissions OWNER TO bwilliam;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.roles (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    updated_at timestamp without time zone,
    is_system boolean DEFAULT false,
    CONSTRAINT valid_description CHECK ((length(description) <= 1000))
);


ALTER TABLE public.roles OWNER TO bwilliam;

--
-- Name: sent_notifications; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.sent_notifications (
    notification_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    recipient_id uuid,
    notification_type character varying(50) NOT NULL,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notification_content text
);


ALTER TABLE public.sent_notifications OWNER TO bwilliam;

--
-- Name: service; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.service (
    service_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    parent_service_id uuid,
    name character varying(255) NOT NULL,
    label character varying(50),
    image_url character varying(255),
    color character varying(20),
    text_below character varying(255),
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    icon character varying(50),
    estimated_time_minutes integer
);


ALTER TABLE public.service OWNER TO bwilliam;

--
-- Name: service_feedback_settings; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.service_feedback_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    template_id uuid,
    is_feedback_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.service_feedback_settings OWNER TO bwilliam;

--
-- Name: service_form_mapping; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.service_form_mapping (
    mapping_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    form_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.service_form_mapping OWNER TO bwilliam;

--
-- Name: service_process; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.service_process (
    service_process_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid,
    name character varying(255) NOT NULL,
    description text,
    order_index integer NOT NULL
);


ALTER TABLE public.service_process OWNER TO bwilliam;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    logout_code_required boolean DEFAULT false,
    closing_code_required boolean DEFAULT false,
    multiple_closing_codes_required boolean DEFAULT false,
    autocall_starts_seconds integer,
    forced_auto_call_menu_timeout_seconds integer DEFAULT 30,
    start_transaction_automatically_seconds integer DEFAULT 30,
    max_missing_clients_repeated_calls integer,
    put_back_missing_client_time_minutes integer,
    min_waiting_time_on_ticket_minutes integer,
    max_waiting_time_on_ticket_minutes integer,
    place_ticket_to_top_of_queue_when_redirected boolean,
    allow_actions_on_ticket_after_redirected_to_service boolean,
    ticket_validity_time_for_customer_feedback_minutes integer,
    sorting_method_of_waiting_tickets character varying(255),
    waiting_time_calculation_source character varying(255),
    num_days_to_calculate_average_waiting_time_of_services integer,
    method_of_calculating_number_of_people_waiting character varying(255),
    enable_virtual_ticket_option boolean,
    identified_client_for_appointment boolean,
    default_signal_type integer,
    smtp_port_number integer,
    smtp_host_name character varying(255),
    smtp_user_name character varying(255),
    smtp_password character varying(255),
    smtp_sender_email_address character varying(255),
    appointment_sender_email character varying(255),
    smtp_ssl boolean,
    smtp_starttls boolean,
    disable_send_same_email_seconds integer,
    license_certificate_notification_email_address character varying(255),
    smpp_host character varying(255),
    smpp_port integer,
    system_id character varying(255),
    smpp_password character varying(255),
    source_address_ton integer,
    source_address_npi integer,
    source_phone_number character varying(255),
    destination_address_ton integer,
    destination_address_npi integer,
    sms_text_encoding character varying(255),
    enable_multipart_messages boolean,
    phone_number character varying(20),
    sms_text text,
    disable_ads_on_ticket_dispenser boolean,
    idle_time_before_displaying_ads_on_ticket_dispenser_seconds integer,
    ads_changing_time_on_ticket_dispenser_seconds integer,
    disable_ads_on_feedback_device boolean,
    idle_time_before_showing_ads_on_feedback_device_seconds integer,
    switch_between_ads_on_feedback_device_seconds integer,
    statistics_export_email_address character varying(255),
    statistics_export_subject character varying(255),
    user_identification_system_type character varying(255),
    user_authentication_method character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    CONSTRAINT settings_autocall_starts_seconds_check CHECK (((autocall_starts_seconds >= 1) AND (autocall_starts_seconds <= 30)))
);


ALTER TABLE public.settings OWNER TO bwilliam;

--
-- Name: sms_api; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.sms_api (
    sms_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    provider character varying(255) NOT NULL,
    api_key character varying(255) NOT NULL,
    username character varying(255),
    password character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.sms_api OWNER TO bwilliam;

--
-- Name: smtp_config; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.smtp_config (
    smtp_id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    host character varying(255) NOT NULL,
    port integer NOT NULL,
    username character varying(255),
    password character varying(255),
    encryption character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.smtp_config OWNER TO bwilliam;

--
-- Name: survey_question_answers; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.survey_question_answers (
    answer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid,
    answer_text text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.survey_question_answers OWNER TO bwilliam;

--
-- Name: survey_questions; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.survey_questions (
    question_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    question_text text NOT NULL,
    is_mandatory boolean,
    question_type character varying(50) NOT NULL,
    thank_you_sms_status boolean DEFAULT false,
    whatsapp_sms_status boolean DEFAULT false,
    whatsapp_sms_content text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.survey_questions OWNER TO bwilliam;

--
-- Name: survey_responses; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.survey_responses (
    response_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    branch_id uuid,
    customer_id uuid,
    user_id uuid,
    counter_id uuid,
    service_id uuid,
    dispenser_id uuid,
    question_id uuid,
    response_data jsonb,
    rating integer,
    comment text,
    selected_option character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.survey_responses OWNER TO bwilliam;

--
-- Name: survey_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.survey_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.survey_templates OWNER TO bwilliam;

--
-- Name: ticket; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket (
    ticket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    service_id uuid,
    customer_id uuid,
    token_number character varying(100),
    generated_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(50) DEFAULT 'Pending'::character varying,
    queue_position integer,
    current_user_id uuid,
    last_updated_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    dispenser_id uuid,
    transferred boolean DEFAULT false,
    picked_up boolean DEFAULT false,
    picked_up_by uuid,
    additional_info jsonb,
    form_id uuid
);


ALTER TABLE public.ticket OWNER TO bwilliam;

--
-- Name: ticket_action_log; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket_action_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    user_id uuid,
    counter_id uuid,
    action character varying(50) NOT NULL,
    action_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    additional_info jsonb
);


ALTER TABLE public.ticket_action_log OWNER TO bwilliam;

--
-- Name: ticket_assignments; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket_assignments (
    assignment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    assigned_user_id uuid,
    assigned_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    resolved boolean DEFAULT false,
    resolved_time timestamp with time zone
);


ALTER TABLE public.ticket_assignments OWNER TO bwilliam;

--
-- Name: ticket_management_settings; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket_management_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL,
    enable_language_change boolean DEFAULT false,
    enable_fullscreen_mode boolean DEFAULT false,
    enable_print_option boolean DEFAULT false,
    disable_cancel_button_mobile boolean DEFAULT false,
    enable_disable_settings boolean DEFAULT false,
    show_token_popup boolean DEFAULT false,
    queue_form_display boolean DEFAULT false,
    category_order_by_name boolean DEFAULT false,
    name_display_on_ticket boolean DEFAULT false,
    logo_on_ticket_screen boolean DEFAULT false,
    company_name_on_ticket boolean DEFAULT false,
    create_multiple_ticket_same_number boolean DEFAULT false,
    display_panel_name_on_ticket boolean DEFAULT false,
    redirect_to_other_website boolean DEFAULT false,
    show_qr_code boolean DEFAULT false,
    show_progress_bar boolean DEFAULT false,
    show_acronym_booking_system boolean DEFAULT false,
    show_categories_on_print_ticket boolean DEFAULT false,
    category_in_row integer DEFAULT 1,
    category_text_font_size character varying(20),
    ticket_font_family character varying(50),
    border_size character varying(20),
    token_number_digit integer DEFAULT 3,
    token_start_from character varying(20) DEFAULT '001'::character varying,
    service_estimate_time integer DEFAULT 10,
    calculate_estimate_waiting_time boolean DEFAULT false,
    category_level_count_waiting_time boolean DEFAULT false,
    ticket_message_1_enable_disable boolean DEFAULT false,
    ticket_message_2_enable_disable boolean DEFAULT false,
    ticket_message_1 character varying(255),
    ticket_message_2 character varying(255),
    capacity_management_enable_disable boolean DEFAULT false,
    capacity_limits integer DEFAULT 0,
    late_coming_feature_enable_disable boolean DEFAULT false,
    multiple_ticket_for_same_customer_enable_disable boolean DEFAULT false,
    fixed_time_enable_disable boolean DEFAULT false,
    enter_time_in_minutes integer DEFAULT 0,
    ticket_generate_if_no_call_enable_disable boolean DEFAULT false,
    restrict_user_to_generate_ticket_enable_disable boolean DEFAULT false,
    custom_css text
);


ALTER TABLE public.ticket_management_settings OWNER TO bwilliam;

--
-- Name: ticket_process; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket_process (
    ticket_process_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    service_process_id uuid,
    counter_id uuid,
    user_id uuid,
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    end_time timestamp with time zone,
    status character varying(50) DEFAULT 'Pending'::character varying
);


ALTER TABLE public.ticket_process OWNER TO bwilliam;

--
-- Name: ticket_workflow_history; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.ticket_workflow_history (
    history_id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid,
    from_stage_id uuid,
    to_stage_id uuid,
    transition_id uuid,
    transition_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ticket_workflow_history OWNER TO bwilliam;

--
-- Name: user_branch; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.user_branch (
    user_branch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    branch_id uuid
);


ALTER TABLE public.user_branch OWNER TO bwilliam;

--
-- Name: user_counter; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.user_counter (
    user_counter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    counter_id uuid
);


ALTER TABLE public.user_counter OWNER TO bwilliam;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.user_roles (
    user_role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    role_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_roles OWNER TO bwilliam;

--
-- Name: users; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    date_of_birth date,
    phone_number character varying(20),
    profile_picture_url character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp with time zone,
    is_active boolean DEFAULT true,
    is_system_admin boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verification_token character varying(255),
    reset_password_token character varying(255),
    reset_password_expiration timestamp with time zone,
    is_owner boolean DEFAULT false,
    updated_at timestamp without time zone,
    complete_kyc boolean DEFAULT false,
    approved_at timestamp without time zone,
    is_approved boolean DEFAULT false,
    branch_id uuid
);


ALTER TABLE public.users OWNER TO bwilliam;

--
-- Name: voice_notification_logs; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.voice_notification_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    recipient_id uuid,
    played_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.voice_notification_logs OWNER TO bwilliam;

--
-- Name: voice_notification_templates; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.voice_notification_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    template_content text NOT NULL,
    font_size character varying(20),
    color character varying(20),
    voice_message_text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.voice_notification_templates OWNER TO bwilliam;

--
-- Name: workflow_stages; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.workflow_stages (
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    stage_name character varying(100) NOT NULL,
    description text
);


ALTER TABLE public.workflow_stages OWNER TO bwilliam;

--
-- Name: workflow_transitions; Type: TABLE; Schema: public; Owner: bwilliam
--

CREATE TABLE public.workflow_transitions (
    transition_id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_stage_id uuid,
    to_stage_id uuid,
    condition character varying(255)
);


ALTER TABLE public.workflow_transitions OWNER TO bwilliam;

--
-- Name: queue_item position; Type: DEFAULT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue_item ALTER COLUMN "position" SET DEFAULT nextval('public.queue_item_position_seq'::regclass);


--
-- Data for Name: active_directory; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.active_directory (ad_id, company_id, domain_name, username, password, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.active_directory (ad_id, company_id, domain_name, username, password, created_at, updated_at, created_by) FROM '$$PATH$$/4158.dat';

--
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.branch (branch_id, company_id, name, portal_code, closing_type, closing_time, default_language, time_zone, enable_appointment, smart_ticket, status, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.branch (branch_id, company_id, name, portal_code, closing_type, closing_time, default_language, time_zone, enable_appointment, smart_ticket, status, created_at, updated_at, created_by) FROM '$$PATH$$/4157.dat';

--
-- Data for Name: company; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.company (company_id, name, address, phone, email, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.company (company_id, name, address, phone, email, created_at, updated_at, created_by) FROM '$$PATH$$/4156.dat';

--
-- Data for Name: counter; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.counter (counter_id, branch_id, name, status, service_id, created_at, updated_at) FROM stdin;
\.
COPY public.counter (counter_id, branch_id, name, status, service_id, created_at, updated_at) FROM '$$PATH$$/4166.dat';

--
-- Data for Name: counter_ticket; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.counter_ticket (counter_ticket_id, counter_id, ticket_id, assigned_timestamp, served) FROM stdin;
\.
COPY public.counter_ticket (counter_ticket_id, counter_id, ticket_id, assigned_timestamp, served) FROM '$$PATH$$/4205.dat';

--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.customers (customer_id, first_name, last_name, email, phone_number, address, city, state, country, postal_code, created_at, updated_at) FROM stdin;
\.
COPY public.customers (customer_id, first_name, last_name, email, phone_number, address, city, state, country, postal_code, created_at, updated_at) FROM '$$PATH$$/4173.dat';

--
-- Data for Name: device_logs; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.device_logs (device_id, device_name, device_type, location, ip_address, last_connection, connection_status, connection_log, created_at, updated_at) FROM stdin;
\.
COPY public.device_logs (device_id, device_name, device_type, location, ip_address, last_connection, connection_status, connection_log, created_at, updated_at) FROM '$$PATH$$/4187.dat';

--
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.devices (device_id, branch_id, device_name, device_type, ip_address, authentication_code, license_key, validity_starts, validity_ends, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, special_service, agent_info, is_activated, created_at, updated_at, created_by, activation_status, activated_at) FROM stdin;
\.
COPY public.devices (device_id, branch_id, device_name, device_type, ip_address, authentication_code, license_key, validity_starts, validity_ends, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, special_service, agent_info, is_activated, created_at, updated_at, created_by, activation_status, activated_at) FROM '$$PATH$$/4198.dat';

--
-- Data for Name: dispenser; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.dispenser (dispenser_id, branch_id, name, language, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, validity_starts, validity_ends, special_service, agent_name, agent_ip, authentication_key, status, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.dispenser (dispenser_id, branch_id, name, language, show_appointment_button, show_authentication_button, show_estimated_waiting_time, show_number_of_waiting_clients, num_services_on_one_ticket, idle_time_before_returning_to_main_screen, ticket_layout, validity_starts, validity_ends, special_service, agent_name, agent_ip, authentication_key, status, created_at, updated_at, created_by) FROM '$$PATH$$/4161.dat';

--
-- Data for Name: dispenser_device_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.dispenser_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM stdin;
\.
COPY public.dispenser_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM '$$PATH$$/4186.dat';

--
-- Data for Name: dispenser_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.dispenser_templates (template_id, template_name, branch_id, template_type, background_color, created_at, updated_at, background_video, background_image, assigned_to, news_scroll) FROM stdin;
\.
COPY public.dispenser_templates (template_id, template_name, branch_id, template_type, background_color, created_at, updated_at, background_video, background_image, assigned_to, news_scroll) FROM '$$PATH$$/4185.dat';

--
-- Data for Name: display_device_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.display_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM stdin;
\.
COPY public.display_device_templates (device_template_id, device_id, template_id, created_at, updated_at) FROM '$$PATH$$/4184.dat';

--
-- Data for Name: display_devices; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.display_devices (device_id, branch_id, device_name, ip_address, authentication_code, created_at, updated_at) FROM stdin;
\.
COPY public.display_devices (device_id, branch_id, device_name, ip_address, authentication_code, created_at, updated_at) FROM '$$PATH$$/4183.dat';

--
-- Data for Name: display_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.display_templates (template_id, template_name, background_image, background_color, split_type, page_style, name_on_display_screen, need_mobile_screen, show_skip_call, show_waiting_call, skip_closed_call, display_screen_tune, show_queue_number, show_missed_queue_number, full_screen_option, show_disclaimer_message, show_missed_queue_with_marquee, template_type, content_source_type, content_endpoint, content_source, section_division, content_configuration, created_at, updated_at) FROM stdin;
\.
COPY public.display_templates (template_id, template_name, background_image, background_color, split_type, page_style, name_on_display_screen, need_mobile_screen, show_skip_call, show_waiting_call, skip_closed_call, display_screen_tune, show_queue_number, show_missed_queue_number, full_screen_option, show_disclaimer_message, show_missed_queue_with_marquee, template_type, content_source_type, content_endpoint, content_source, section_division, content_configuration, created_at, updated_at) FROM '$$PATH$$/4196.dat';

--
-- Data for Name: file_uploads; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.file_uploads (upload_id, folder_name, folder_location, file_name, file_type, created_at, upload_for, uploaded_by, old_file_name) FROM stdin;
\.
COPY public.file_uploads (upload_id, folder_name, folder_location, file_name, file_type, created_at, upload_for, uploaded_by, old_file_name) FROM '$$PATH$$/4199.dat';

--
-- Data for Name: form_fields; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.form_fields (field_id, form_id, label, field_type, is_required, options_endpoint, is_verified, verification_endpoint, order_index, created_by, created_at, updated_at, options) FROM stdin;
\.
COPY public.form_fields (field_id, form_id, label, field_type, is_required, options_endpoint, is_verified, verification_endpoint, order_index, created_by, created_at, updated_at, options) FROM '$$PATH$$/4207.dat';

--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.forms (form_id, form_name, verification_endpoint, created_by, created_at, updated_at, needs_verification) FROM stdin;
\.
COPY public.forms (form_id, form_name, verification_endpoint, created_by, created_at, updated_at, needs_verification) FROM '$$PATH$$/4206.dat';

--
-- Data for Name: fx_rates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.fx_rates (rate_id, currency_code, rate_date, exchange_rate, template_id, created_at, updated_at) FROM stdin;
\.
COPY public.fx_rates (rate_id, currency_code, rate_date, exchange_rate, template_id, created_at, updated_at) FROM '$$PATH$$/4200.dat';

--
-- Data for Name: media_content; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.media_content (content_id, content_type, content_url, assigned_to, assigned_id, branch_id, dispenser_template_id, display_template_id, created_at, updated_at) FROM stdin;
\.
COPY public.media_content (content_id, content_type, content_url, assigned_to, assigned_id, branch_id, dispenser_template_id, display_template_id, created_at, updated_at) FROM '$$PATH$$/4197.dat';

--
-- Data for Name: notification_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.notification_templates (template_id, template_name, template_type, subject, template_content, created_at, updated_at) FROM stdin;
\.
COPY public.notification_templates (template_id, template_name, template_type, subject, template_content, created_at, updated_at) FROM '$$PATH$$/4179.dat';

--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.permissions (route_path, route_method, permission_name, description, controller_function, middleware, created_at, updated_at, permission_id) FROM stdin;
\.
COPY public.permissions (route_path, route_method, permission_name, description, controller_function, middleware, created_at, updated_at, permission_id) FROM '$$PATH$$/4194.dat';

--
-- Data for Name: queue; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.queue (queue_id, branch_id, service_id, is_default, algorithm, created_at, updated_at) FROM stdin;
\.
COPY public.queue (queue_id, branch_id, service_id, is_default, algorithm, created_at, updated_at) FROM '$$PATH$$/4201.dat';

--
-- Data for Name: queue_item; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.queue_item (queue_item_id, queue_id, ticket_id, counter_id, "position", served, created_at, updated_at) FROM stdin;
\.
COPY public.queue_item (queue_item_id, queue_id, ticket_id, counter_id, "position", served, created_at, updated_at) FROM '$$PATH$$/4203.dat';

--
-- Data for Name: queue_log; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.queue_log (log_id, action_type, ticket_id, user_id, action_timestamp) FROM stdin;
\.
COPY public.queue_log (log_id, action_type, ticket_id, user_id, action_timestamp) FROM '$$PATH$$/4204.dat';

--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.role_permissions (role_permission_id, role_id, permission_id, created_at, tenant_id) FROM stdin;
\.
COPY public.role_permissions (role_permission_id, role_id, permission_id, created_at, tenant_id) FROM '$$PATH$$/4164.dat';

--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.roles (role_id, role_name, description, created_at, is_active, updated_at, is_system) FROM stdin;
\.
COPY public.roles (role_id, role_name, description, created_at, is_active, updated_at, is_system) FROM '$$PATH$$/4163.dat';

--
-- Data for Name: sent_notifications; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.sent_notifications (notification_id, template_id, recipient_id, notification_type, sent_at, notification_content) FROM stdin;
\.
COPY public.sent_notifications (notification_id, template_id, recipient_id, notification_type, sent_at, notification_content) FROM '$$PATH$$/4180.dat';

--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.service (service_id, branch_id, parent_service_id, name, label, image_url, color, text_below, description, created_at, updated_at, created_by, icon, estimated_time_minutes) FROM stdin;
\.
COPY public.service (service_id, branch_id, parent_service_id, name, label, image_url, color, text_below, description, created_at, updated_at, created_by, icon, estimated_time_minutes) FROM '$$PATH$$/4188.dat';

--
-- Data for Name: service_feedback_settings; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.service_feedback_settings (setting_id, service_id, template_id, is_feedback_enabled, created_at, updated_at) FROM stdin;
\.
COPY public.service_feedback_settings (setting_id, service_id, template_id, is_feedback_enabled, created_at, updated_at) FROM '$$PATH$$/4178.dat';

--
-- Data for Name: service_form_mapping; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.service_form_mapping (mapping_id, service_id, form_id, created_at, updated_at) FROM stdin;
\.
COPY public.service_form_mapping (mapping_id, service_id, form_id, created_at, updated_at) FROM '$$PATH$$/4208.dat';

--
-- Data for Name: service_process; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.service_process (service_process_id, service_id, name, description, order_index) FROM stdin;
\.
COPY public.service_process (service_process_id, service_id, name, description, order_index) FROM '$$PATH$$/4167.dat';

--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.settings (setting_id, company_id, logout_code_required, closing_code_required, multiple_closing_codes_required, autocall_starts_seconds, forced_auto_call_menu_timeout_seconds, start_transaction_automatically_seconds, max_missing_clients_repeated_calls, put_back_missing_client_time_minutes, min_waiting_time_on_ticket_minutes, max_waiting_time_on_ticket_minutes, place_ticket_to_top_of_queue_when_redirected, allow_actions_on_ticket_after_redirected_to_service, ticket_validity_time_for_customer_feedback_minutes, sorting_method_of_waiting_tickets, waiting_time_calculation_source, num_days_to_calculate_average_waiting_time_of_services, method_of_calculating_number_of_people_waiting, enable_virtual_ticket_option, identified_client_for_appointment, default_signal_type, smtp_port_number, smtp_host_name, smtp_user_name, smtp_password, smtp_sender_email_address, appointment_sender_email, smtp_ssl, smtp_starttls, disable_send_same_email_seconds, license_certificate_notification_email_address, smpp_host, smpp_port, system_id, smpp_password, source_address_ton, source_address_npi, source_phone_number, destination_address_ton, destination_address_npi, sms_text_encoding, enable_multipart_messages, phone_number, sms_text, disable_ads_on_ticket_dispenser, idle_time_before_displaying_ads_on_ticket_dispenser_seconds, ads_changing_time_on_ticket_dispenser_seconds, disable_ads_on_feedback_device, idle_time_before_showing_ads_on_feedback_device_seconds, switch_between_ads_on_feedback_device_seconds, statistics_export_email_address, statistics_export_subject, user_identification_system_type, user_authentication_method, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.settings (setting_id, company_id, logout_code_required, closing_code_required, multiple_closing_codes_required, autocall_starts_seconds, forced_auto_call_menu_timeout_seconds, start_transaction_automatically_seconds, max_missing_clients_repeated_calls, put_back_missing_client_time_minutes, min_waiting_time_on_ticket_minutes, max_waiting_time_on_ticket_minutes, place_ticket_to_top_of_queue_when_redirected, allow_actions_on_ticket_after_redirected_to_service, ticket_validity_time_for_customer_feedback_minutes, sorting_method_of_waiting_tickets, waiting_time_calculation_source, num_days_to_calculate_average_waiting_time_of_services, method_of_calculating_number_of_people_waiting, enable_virtual_ticket_option, identified_client_for_appointment, default_signal_type, smtp_port_number, smtp_host_name, smtp_user_name, smtp_password, smtp_sender_email_address, appointment_sender_email, smtp_ssl, smtp_starttls, disable_send_same_email_seconds, license_certificate_notification_email_address, smpp_host, smpp_port, system_id, smpp_password, source_address_ton, source_address_npi, source_phone_number, destination_address_ton, destination_address_npi, sms_text_encoding, enable_multipart_messages, phone_number, sms_text, disable_ads_on_ticket_dispenser, idle_time_before_displaying_ads_on_ticket_dispenser_seconds, ads_changing_time_on_ticket_dispenser_seconds, disable_ads_on_feedback_device, idle_time_before_showing_ads_on_feedback_device_seconds, switch_between_ads_on_feedback_device_seconds, statistics_export_email_address, statistics_export_subject, user_identification_system_type, user_authentication_method, created_at, updated_at, created_by) FROM '$$PATH$$/4162.dat';

--
-- Data for Name: sms_api; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.sms_api (sms_id, company_id, provider, api_key, username, password, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.sms_api (sms_id, company_id, provider, api_key, username, password, created_at, updated_at, created_by) FROM '$$PATH$$/4160.dat';

--
-- Data for Name: smtp_config; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.smtp_config (smtp_id, company_id, host, port, username, password, encryption, created_at, updated_at, created_by) FROM stdin;
\.
COPY public.smtp_config (smtp_id, company_id, host, port, username, password, encryption, created_at, updated_at, created_by) FROM '$$PATH$$/4159.dat';

--
-- Data for Name: survey_question_answers; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.survey_question_answers (answer_id, question_id, answer_text, created_at, updated_at) FROM stdin;
\.
COPY public.survey_question_answers (answer_id, question_id, answer_text, created_at, updated_at) FROM '$$PATH$$/4176.dat';

--
-- Data for Name: survey_questions; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.survey_questions (question_id, template_id, question_text, is_mandatory, question_type, thank_you_sms_status, whatsapp_sms_status, whatsapp_sms_content, created_at, updated_at) FROM stdin;
\.
COPY public.survey_questions (question_id, template_id, question_text, is_mandatory, question_type, thank_you_sms_status, whatsapp_sms_status, whatsapp_sms_content, created_at, updated_at) FROM '$$PATH$$/4175.dat';

--
-- Data for Name: survey_responses; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.survey_responses (response_id, template_id, branch_id, customer_id, user_id, counter_id, service_id, dispenser_id, question_id, response_data, rating, comment, selected_option, created_at) FROM stdin;
\.
COPY public.survey_responses (response_id, template_id, branch_id, customer_id, user_id, counter_id, service_id, dispenser_id, question_id, response_data, rating, comment, selected_option, created_at) FROM '$$PATH$$/4177.dat';

--
-- Data for Name: survey_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.survey_templates (template_id, template_name, created_at, updated_at) FROM stdin;
\.
COPY public.survey_templates (template_id, template_name, created_at, updated_at) FROM '$$PATH$$/4174.dat';

--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket (ticket_id, branch_id, service_id, customer_id, token_number, generated_time, status, queue_position, current_user_id, last_updated_time, dispenser_id, transferred, picked_up, picked_up_by, additional_info, form_id) FROM stdin;
\.
COPY public.ticket (ticket_id, branch_id, service_id, customer_id, token_number, generated_time, status, queue_position, current_user_id, last_updated_time, dispenser_id, transferred, picked_up, picked_up_by, additional_info, form_id) FROM '$$PATH$$/4189.dat';

--
-- Data for Name: ticket_action_log; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket_action_log (log_id, ticket_id, user_id, counter_id, action, action_time, additional_info) FROM stdin;
\.
COPY public.ticket_action_log (log_id, ticket_id, user_id, counter_id, action, action_time, additional_info) FROM '$$PATH$$/4171.dat';

--
-- Data for Name: ticket_assignments; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket_assignments (assignment_id, ticket_id, assigned_user_id, assigned_time, resolved, resolved_time) FROM stdin;
\.
COPY public.ticket_assignments (assignment_id, ticket_id, assigned_user_id, assigned_time, resolved, resolved_time) FROM '$$PATH$$/4190.dat';

--
-- Data for Name: ticket_management_settings; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket_management_settings (setting_id, enable_language_change, enable_fullscreen_mode, enable_print_option, disable_cancel_button_mobile, enable_disable_settings, show_token_popup, queue_form_display, category_order_by_name, name_display_on_ticket, logo_on_ticket_screen, company_name_on_ticket, create_multiple_ticket_same_number, display_panel_name_on_ticket, redirect_to_other_website, show_qr_code, show_progress_bar, show_acronym_booking_system, show_categories_on_print_ticket, category_in_row, category_text_font_size, ticket_font_family, border_size, token_number_digit, token_start_from, service_estimate_time, calculate_estimate_waiting_time, category_level_count_waiting_time, ticket_message_1_enable_disable, ticket_message_2_enable_disable, ticket_message_1, ticket_message_2, capacity_management_enable_disable, capacity_limits, late_coming_feature_enable_disable, multiple_ticket_for_same_customer_enable_disable, fixed_time_enable_disable, enter_time_in_minutes, ticket_generate_if_no_call_enable_disable, restrict_user_to_generate_ticket_enable_disable, custom_css) FROM stdin;
\.
COPY public.ticket_management_settings (setting_id, enable_language_change, enable_fullscreen_mode, enable_print_option, disable_cancel_button_mobile, enable_disable_settings, show_token_popup, queue_form_display, category_order_by_name, name_display_on_ticket, logo_on_ticket_screen, company_name_on_ticket, create_multiple_ticket_same_number, display_panel_name_on_ticket, redirect_to_other_website, show_qr_code, show_progress_bar, show_acronym_booking_system, show_categories_on_print_ticket, category_in_row, category_text_font_size, ticket_font_family, border_size, token_number_digit, token_start_from, service_estimate_time, calculate_estimate_waiting_time, category_level_count_waiting_time, ticket_message_1_enable_disable, ticket_message_2_enable_disable, ticket_message_1, ticket_message_2, capacity_management_enable_disable, capacity_limits, late_coming_feature_enable_disable, multiple_ticket_for_same_customer_enable_disable, fixed_time_enable_disable, enter_time_in_minutes, ticket_generate_if_no_call_enable_disable, restrict_user_to_generate_ticket_enable_disable, custom_css) FROM '$$PATH$$/4172.dat';

--
-- Data for Name: ticket_process; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket_process (ticket_process_id, ticket_id, service_process_id, counter_id, user_id, start_time, end_time, status) FROM stdin;
\.
COPY public.ticket_process (ticket_process_id, ticket_id, service_process_id, counter_id, user_id, start_time, end_time, status) FROM '$$PATH$$/4168.dat';

--
-- Data for Name: ticket_workflow_history; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.ticket_workflow_history (history_id, ticket_id, from_stage_id, to_stage_id, transition_id, transition_timestamp) FROM stdin;
\.
COPY public.ticket_workflow_history (history_id, ticket_id, from_stage_id, to_stage_id, transition_id, transition_timestamp) FROM '$$PATH$$/4193.dat';

--
-- Data for Name: user_branch; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.user_branch (user_branch_id, user_id, branch_id) FROM stdin;
\.
COPY public.user_branch (user_branch_id, user_id, branch_id) FROM '$$PATH$$/4169.dat';

--
-- Data for Name: user_counter; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.user_counter (user_counter_id, user_id, counter_id) FROM stdin;
\.
COPY public.user_counter (user_counter_id, user_id, counter_id) FROM '$$PATH$$/4170.dat';

--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.user_roles (user_role_id, user_id, role_id, created_at) FROM stdin;
\.
COPY public.user_roles (user_role_id, user_id, role_id, created_at) FROM '$$PATH$$/4195.dat';

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.users (user_id, username, email, password, first_name, last_name, date_of_birth, phone_number, profile_picture_url, created_at, last_login, is_active, is_system_admin, is_verified, verification_token, reset_password_token, reset_password_expiration, is_owner, updated_at, complete_kyc, approved_at, is_approved, branch_id) FROM stdin;
\.
COPY public.users (user_id, username, email, password, first_name, last_name, date_of_birth, phone_number, profile_picture_url, created_at, last_login, is_active, is_system_admin, is_verified, verification_token, reset_password_token, reset_password_expiration, is_owner, updated_at, complete_kyc, approved_at, is_approved, branch_id) FROM '$$PATH$$/4165.dat';

--
-- Data for Name: voice_notification_logs; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.voice_notification_logs (log_id, template_id, recipient_id, played_at) FROM stdin;
\.
COPY public.voice_notification_logs (log_id, template_id, recipient_id, played_at) FROM '$$PATH$$/4182.dat';

--
-- Data for Name: voice_notification_templates; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.voice_notification_templates (template_id, template_name, template_content, font_size, color, voice_message_text, created_at, updated_at) FROM stdin;
\.
COPY public.voice_notification_templates (template_id, template_name, template_content, font_size, color, voice_message_text, created_at, updated_at) FROM '$$PATH$$/4181.dat';

--
-- Data for Name: workflow_stages; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.workflow_stages (stage_id, stage_name, description) FROM stdin;
\.
COPY public.workflow_stages (stage_id, stage_name, description) FROM '$$PATH$$/4191.dat';

--
-- Data for Name: workflow_transitions; Type: TABLE DATA; Schema: public; Owner: bwilliam
--

COPY public.workflow_transitions (transition_id, from_stage_id, to_stage_id, condition) FROM stdin;
\.
COPY public.workflow_transitions (transition_id, from_stage_id, to_stage_id, condition) FROM '$$PATH$$/4192.dat';

--
-- Name: queue_item_position_seq; Type: SEQUENCE SET; Schema: public; Owner: bwilliam
--

SELECT pg_catalog.setval('public.queue_item_position_seq', 1, false);


--
-- Name: active_directory active_directory_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.active_directory
    ADD CONSTRAINT active_directory_pkey PRIMARY KEY (ad_id);


--
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (branch_id);


--
-- Name: company company_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_pkey PRIMARY KEY (company_id);


--
-- Name: counter counter_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.counter
    ADD CONSTRAINT counter_pkey PRIMARY KEY (counter_id);


--
-- Name: counter_ticket counter_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_pkey PRIMARY KEY (counter_ticket_id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: device_logs device_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.device_logs
    ADD CONSTRAINT device_logs_pkey PRIMARY KEY (device_id);


--
-- Name: devices devices_device_name_ip_address_authentication_code_license__key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_device_name_ip_address_authentication_code_license__key UNIQUE (device_name) INCLUDE (ip_address, authentication_code, license_key);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (device_id);


--
-- Name: dispenser_device_templates dispenser_device_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_pkey PRIMARY KEY (device_template_id);


--
-- Name: dispenser dispenser_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser
    ADD CONSTRAINT dispenser_pkey PRIMARY KEY (dispenser_id);


--
-- Name: dispenser_templates dispenser_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser_templates
    ADD CONSTRAINT dispenser_templates_pkey PRIMARY KEY (template_id);


--
-- Name: display_device_templates display_device_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_pkey PRIMARY KEY (device_template_id);


--
-- Name: display_devices display_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_devices
    ADD CONSTRAINT display_devices_pkey PRIMARY KEY (device_id);


--
-- Name: display_templates display_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_templates
    ADD CONSTRAINT display_templates_pkey PRIMARY KEY (template_id);


--
-- Name: file_uploads file_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_pkey PRIMARY KEY (upload_id);


--
-- Name: form_fields form_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.form_fields
    ADD CONSTRAINT form_fields_pkey PRIMARY KEY (field_id);


--
-- Name: forms forms_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (form_id);


--
-- Name: fx_rates fx_rates_currency_code_rate_date_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_currency_code_rate_date_key UNIQUE (currency_code, rate_date);


--
-- Name: fx_rates fx_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_pkey PRIMARY KEY (rate_id);


--
-- Name: media_content media_content_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT media_content_pkey PRIMARY KEY (content_id);


--
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (template_id);


--
-- Name: permissions permissions_permission_name_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_permission_name_key UNIQUE (permission_name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission_id);


--
-- Name: permissions permissions_route_path_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_route_path_key UNIQUE (route_path);


--
-- Name: queue_item queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_pkey PRIMARY KEY (queue_item_id);


--
-- Name: queue_log queue_log_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue_log
    ADD CONSTRAINT queue_log_pkey PRIMARY KEY (log_id);


--
-- Name: queue queue_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue
    ADD CONSTRAINT queue_pkey PRIMARY KEY (queue_id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_permission_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: sent_notifications sent_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.sent_notifications
    ADD CONSTRAINT sent_notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: service_feedback_settings service_feedback_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_pkey PRIMARY KEY (setting_id);


--
-- Name: service_feedback_settings service_feedback_settings_unique; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_unique UNIQUE (service_id, template_id);


--
-- Name: service_form_mapping service_form_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_pkey PRIMARY KEY (mapping_id);


--
-- Name: service_form_mapping service_form_mapping_service_id_form_id_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_service_id_form_id_key UNIQUE (service_id) INCLUDE (form_id);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (service_id);


--
-- Name: service_process service_process_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_process
    ADD CONSTRAINT service_process_pkey PRIMARY KEY (service_process_id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


--
-- Name: sms_api sms_api_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.sms_api
    ADD CONSTRAINT sms_api_pkey PRIMARY KEY (sms_id);


--
-- Name: smtp_config smtp_config_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.smtp_config
    ADD CONSTRAINT smtp_config_pkey PRIMARY KEY (smtp_id);


--
-- Name: survey_question_answers survey_question_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_question_answers
    ADD CONSTRAINT survey_question_answers_pkey PRIMARY KEY (answer_id);


--
-- Name: survey_questions survey_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_pkey PRIMARY KEY (question_id);


--
-- Name: survey_responses survey_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_pkey PRIMARY KEY (response_id);


--
-- Name: survey_templates survey_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_templates
    ADD CONSTRAINT survey_templates_pkey PRIMARY KEY (template_id);


--
-- Name: ticket_action_log ticket_action_log_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_pkey PRIMARY KEY (log_id);


--
-- Name: ticket_assignments ticket_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: ticket_management_settings ticket_management_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_management_settings
    ADD CONSTRAINT ticket_management_settings_pkey PRIMARY KEY (setting_id);


--
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (ticket_id);


--
-- Name: ticket_process ticket_process_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_pkey PRIMARY KEY (ticket_process_id);


--
-- Name: ticket_workflow_history ticket_workflow_history_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_pkey PRIMARY KEY (history_id);


--
-- Name: role_permissions unique_role_permission; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id, tenant_id);


--
-- Name: user_branch user_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_pkey PRIMARY KEY (user_branch_id);


--
-- Name: user_counter user_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_pkey PRIMARY KEY (user_counter_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: voice_notification_logs voice_notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.voice_notification_logs
    ADD CONSTRAINT voice_notification_logs_pkey PRIMARY KEY (log_id);


--
-- Name: voice_notification_templates voice_notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.voice_notification_templates
    ADD CONSTRAINT voice_notification_templates_pkey PRIMARY KEY (template_id);


--
-- Name: workflow_stages workflow_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.workflow_stages
    ADD CONSTRAINT workflow_stages_pkey PRIMARY KEY (stage_id);


--
-- Name: workflow_transitions workflow_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (transition_id);


--
-- Name: ticket ticket_status_update_trigger; Type: TRIGGER; Schema: public; Owner: bwilliam
--

CREATE TRIGGER ticket_status_update_trigger AFTER UPDATE OF status ON public.ticket FOR EACH ROW WHEN (((old.status)::text <> (new.status)::text)) EXECUTE FUNCTION public.update_ticket_position();


--
-- Name: active_directory active_directory_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.active_directory
    ADD CONSTRAINT active_directory_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);


--
-- Name: branch branch_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);


--
-- Name: counter counter_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.counter
    ADD CONSTRAINT counter_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: counter_ticket counter_ticket_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: counter_ticket counter_ticket_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.counter_ticket
    ADD CONSTRAINT counter_ticket_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id);


--
-- Name: devices devices_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: dispenser dispenser_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser
    ADD CONSTRAINT dispenser_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: dispenser_device_templates dispenser_device_templates_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.dispenser(dispenser_id);


--
-- Name: dispenser_device_templates dispenser_device_templates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser_device_templates
    ADD CONSTRAINT dispenser_device_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id);


--
-- Name: dispenser_templates dispenser_templates_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.dispenser_templates
    ADD CONSTRAINT dispenser_templates_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: display_device_templates display_device_templates_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) NOT VALID;


--
-- Name: display_device_templates display_device_templates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_device_templates
    ADD CONSTRAINT display_device_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id) NOT VALID;


--
-- Name: display_devices display_devices_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.display_devices
    ADD CONSTRAINT display_devices_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: media_content fk_dispenser_template; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT fk_dispenser_template FOREIGN KEY (dispenser_template_id) REFERENCES public.dispenser_templates(template_id);


--
-- Name: media_content fk_display_template; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT fk_display_template FOREIGN KEY (display_template_id) REFERENCES public.display_templates(template_id);


--
-- Name: form_fields form_fields_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.form_fields
    ADD CONSTRAINT form_fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id) ON DELETE CASCADE;


--
-- Name: fx_rates fx_rates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.dispenser_templates(template_id) NOT VALID;


--
-- Name: queue_item queue_item_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: queue_item queue_item_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.queue_item
    ADD CONSTRAINT queue_item_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.queue(queue_id);


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- Name: sent_notifications sent_notifications_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.sent_notifications
    ADD CONSTRAINT sent_notifications_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.notification_templates(template_id);


--
-- Name: service_feedback_settings service_feedback_settings_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_feedback_settings
    ADD CONSTRAINT service_feedback_settings_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);


--
-- Name: service_form_mapping service_form_mapping_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id) ON DELETE CASCADE;


--
-- Name: service_form_mapping service_form_mapping_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service_form_mapping
    ADD CONSTRAINT service_form_mapping_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id) ON DELETE CASCADE;


--
-- Name: service service_parent_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_parent_service_id_fkey FOREIGN KEY (parent_service_id) REFERENCES public.service(service_id);


--
-- Name: settings settings_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);


--
-- Name: sms_api sms_api_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.sms_api
    ADD CONSTRAINT sms_api_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);


--
-- Name: smtp_config smtp_config_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.smtp_config
    ADD CONSTRAINT smtp_config_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(company_id);


--
-- Name: survey_question_answers survey_question_answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_question_answers
    ADD CONSTRAINT survey_question_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id);


--
-- Name: survey_questions survey_questions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);


--
-- Name: survey_responses survey_responses_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: survey_responses survey_responses_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: survey_responses survey_responses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: survey_responses survey_responses_dispenser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_dispenser_id_fkey FOREIGN KEY (dispenser_id) REFERENCES public.dispenser(dispenser_id);


--
-- Name: survey_responses survey_responses_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id);


--
-- Name: survey_responses survey_responses_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.survey_templates(template_id);


--
-- Name: survey_responses survey_responses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: ticket_action_log ticket_action_log_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: ticket_action_log ticket_action_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_action_log
    ADD CONSTRAINT ticket_action_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: ticket_assignments ticket_assignments_assigned_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_assigned_user_id_fkey FOREIGN KEY (assigned_user_id) REFERENCES public.users(user_id);


--
-- Name: ticket_assignments ticket_assignments_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_assignments
    ADD CONSTRAINT ticket_assignments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id) ON DELETE CASCADE;


--
-- Name: ticket ticket_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: ticket_process ticket_process_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: ticket_process ticket_process_service_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_process
    ADD CONSTRAINT ticket_process_service_process_id_fkey FOREIGN KEY (service_process_id) REFERENCES public.service_process(service_process_id);


--
-- Name: ticket_workflow_history ticket_workflow_history_from_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_from_stage_id_fkey FOREIGN KEY (from_stage_id) REFERENCES public.workflow_stages(stage_id);


--
-- Name: ticket_workflow_history ticket_workflow_history_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(ticket_id);


--
-- Name: ticket_workflow_history ticket_workflow_history_to_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_to_stage_id_fkey FOREIGN KEY (to_stage_id) REFERENCES public.workflow_stages(stage_id);


--
-- Name: ticket_workflow_history ticket_workflow_history_transition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.ticket_workflow_history
    ADD CONSTRAINT ticket_workflow_history_transition_id_fkey FOREIGN KEY (transition_id) REFERENCES public.workflow_transitions(transition_id);


--
-- Name: user_branch user_branch_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- Name: user_branch user_branch_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_branch
    ADD CONSTRAINT user_branch_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: user_counter user_counter_counter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_counter_id_fkey FOREIGN KEY (counter_id) REFERENCES public.counter(counter_id);


--
-- Name: user_counter user_counter_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.user_counter
    ADD CONSTRAINT user_counter_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: voice_notification_logs voice_notification_logs_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.voice_notification_logs
    ADD CONSTRAINT voice_notification_logs_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.voice_notification_templates(template_id);


--
-- Name: workflow_transitions workflow_transitions_from_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_stage_id_fkey FOREIGN KEY (from_stage_id) REFERENCES public.workflow_stages(stage_id);


--
-- Name: workflow_transitions workflow_transitions_to_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bwilliam
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_stage_id_fkey FOREIGN KEY (to_stage_id) REFERENCES public.workflow_stages(stage_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: bwilliam
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      