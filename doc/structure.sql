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
-- Name: versions_partitions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA versions_partitions;


--
-- Name: always_fail_on_insert(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.always_fail_on_insert(table_name text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
           BEGIN
             RAISE EXCEPTION 'partitioned table "%" does not support direct inserts, you should be inserting directly into child tables', table_name;
             RETURN false;
           END;
          $$;


--
-- Name: dynamic_annotation_fields_value(character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dynamic_annotation_fields_value(field_name character varying, value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      DECLARE
        dynamic_field_value TEXT;
      BEGIN
        IF field_name = 'external_id' OR field_name = 'smooch_user_id' OR field_name = 'verification_status_status'
        THEN
          SELECT value INTO dynamic_field_value;
        ELSE
          SELECT NULL INTO dynamic_field_value;
        END IF;
        RETURN dynamic_field_value;
      END;
      $$;


--
-- Name: task_fieldset(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_fieldset(annotation_type text, data text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
      DECLARE
        fieldset TEXT;
      BEGIN
        IF annotation_type = 'task' AND data LIKE '%fieldset: %'
        THEN
          SELECT REGEXP_REPLACE(data, '^.*fieldset: ([0-9a-z_]+).*$', '\1') INTO fieldset;
        ELSE
          SELECT NULL INTO fieldset;
        END IF;
        RETURN fieldset;
      END;
      $_$;


--
-- Name: task_team_task_id(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_team_task_id(annotation_type text, data text) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
      DECLARE
        team_task_id INTEGER;
      BEGIN
        IF annotation_type = 'task' AND data LIKE '%team_task_id: %'
        THEN
          SELECT REGEXP_REPLACE(data, '^.*team_task_id: ([0-9]+).*$', '\1')::int INTO team_task_id;
        ELSE
          SELECT NULL INTO team_task_id;
        END IF;
        RETURN team_task_id;
      END;
      $_$;


--
-- Name: version_annotation_type(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.version_annotation_type(event_type text, object_after text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
      DECLARE
        name TEXT;
      BEGIN
        IF event_type = 'create_dynamic' OR event_type = 'update_dynamic'
        THEN
          SELECT REGEXP_REPLACE(object_after, '^.*annotation_type":"([^"]+).*$', '\1') INTO name;
        ELSE
          SELECT '' INTO name;
        END IF;
        RETURN name;
      END;
      $_$;


--
-- Name: version_field_name(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.version_field_name(event_type text, object_after text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
      DECLARE
        name TEXT;
      BEGIN
        IF event_type = 'create_dynamicannotationfield' OR event_type = 'update_dynamicannotationfield'
        THEN
          SELECT REGEXP_REPLACE(object_after, '^.*field_name":"([^"]+).*$', '\1') INTO name;
        ELSE
          SELECT '' INTO name;
        END IF;
        RETURN name;
      END;
      $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_sources (
    id integer NOT NULL,
    account_id integer,
    source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_sources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_sources_id_seq OWNED BY public.account_sources.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    user_id integer,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    team_id integer,
    omniauth_info text,
    uid character varying,
    provider character varying,
    token character varying,
    email character varying
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annotations (
    id integer NOT NULL,
    annotation_type character varying NOT NULL,
    version_index integer,
    annotated_type character varying,
    annotated_id integer,
    annotator_type character varying,
    annotator_id integer,
    entities text,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    file character varying,
    attribution text,
    lock_version integer DEFAULT 0 NOT NULL,
    locked boolean DEFAULT false,
    fragment text
);


--
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.annotations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.annotations_id_seq OWNED BY public.annotations.id;


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    access_token character varying DEFAULT ''::character varying NOT NULL,
    expire_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    application character varying
);


--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id integer NOT NULL,
    assigned_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_type character varying,
    assigner_id integer,
    message text
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: bot_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_resources (
    id integer NOT NULL,
    uuid character varying DEFAULT ''::character varying NOT NULL,
    title character varying DEFAULT ''::character varying NOT NULL,
    content character varying DEFAULT ''::character varying NOT NULL,
    feed_url character varying,
    number_of_articles integer DEFAULT 3,
    team_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: bot_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_resources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_resources_id_seq OWNED BY public.bot_resources.id;


--
-- Name: bounces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bounces (
    id integer NOT NULL,
    email character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bounces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bounces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bounces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bounces_id_seq OWNED BY public.bounces.id;


--
-- Name: dynamic_annotation_annotation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dynamic_annotation_annotation_types (
    annotation_type character varying NOT NULL,
    label character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    singleton boolean DEFAULT true,
    json_schema jsonb
);


--
-- Name: dynamic_annotation_field_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dynamic_annotation_field_instances (
    name character varying NOT NULL,
    field_type character varying NOT NULL,
    annotation_type character varying NOT NULL,
    label character varying NOT NULL,
    description text,
    optional boolean DEFAULT true,
    settings text,
    default_value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: dynamic_annotation_field_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dynamic_annotation_field_types (
    field_type character varying NOT NULL,
    label character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: dynamic_annotation_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dynamic_annotation_fields (
    id integer NOT NULL,
    annotation_id integer NOT NULL,
    field_name character varying NOT NULL,
    annotation_type character varying NOT NULL,
    field_type character varying NOT NULL,
    value text NOT NULL,
    value_json jsonb DEFAULT '"{}"'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: login_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_activities (
    id integer NOT NULL,
    scope character varying,
    strategy character varying,
    identity character varying,
    success boolean,
    failure_reason character varying,
    user_type character varying,
    user_id integer,
    context character varying,
    ip character varying,
    user_agent text,
    referrer text,
    created_at timestamp without time zone
);


--
-- Name: login_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_activities_id_seq OWNED BY public.login_activities.id;


--
-- Name: medias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medias (
    id integer NOT NULL,
    user_id integer,
    account_id integer,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    quote character varying,
    type character varying,
    file character varying
);


--
-- Name: medias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.medias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.medias_id_seq OWNED BY public.medias.id;


--
-- Name: new_dynamic_annotation_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.new_dynamic_annotation_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_dynamic_annotation_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.new_dynamic_annotation_fields_id_seq OWNED BY public.dynamic_annotation_fields.id;


--
-- Name: pghero_query_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pghero_query_stats (
    id integer NOT NULL,
    database text,
    "user" text,
    query text,
    query_hash bigint,
    total_time double precision,
    calls bigint,
    captured_at timestamp without time zone
);


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pghero_query_stats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pghero_query_stats_id_seq OWNED BY public.pghero_query_stats.id;


--
-- Name: project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_groups (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text,
    team_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_groups_id_seq OWNED BY public.project_groups.id;


--
-- Name: project_media_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_media_users (
    id integer NOT NULL,
    project_media_id integer,
    user_id integer,
    read boolean DEFAULT false NOT NULL
);


--
-- Name: project_media_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_media_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_media_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_media_users_id_seq OWNED BY public.project_media_users.id;


--
-- Name: project_medias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_medias (
    id integer NOT NULL,
    media_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    cached_annotations_count integer DEFAULT 0,
    archived integer DEFAULT 0,
    targets_count integer DEFAULT 0 NOT NULL,
    sources_count integer DEFAULT 0 NOT NULL,
    team_id integer,
    read boolean DEFAULT false NOT NULL,
    source_id integer,
    project_id integer,
    last_seen integer,
    channel integer DEFAULT 0
);


--
-- Name: project_medias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_medias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_medias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_medias_id_seq OWNED BY public.project_medias.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    user_id integer,
    team_id integer,
    title character varying,
    description text,
    lead_image character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    archived integer DEFAULT 0,
    settings text,
    token character varying,
    assignments_count integer DEFAULT 0,
    project_group_id integer,
    privacy integer DEFAULT 0 NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationships (
    id integer NOT NULL,
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    relationship_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    weight double precision DEFAULT 0.0,
    confirmed_by integer,
    confirmed_at timestamp without time zone
);


--
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relationships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relationships_id_seq OWNED BY public.relationships.id;


--
-- Name: saved_searches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_searches (
    id integer NOT NULL,
    title character varying NOT NULL,
    team_id integer NOT NULL,
    filters json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: saved_searches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.saved_searches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: saved_searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.saved_searches_id_seq OWNED BY public.saved_searches.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shortened_urls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shortened_urls (
    id integer NOT NULL,
    owner_id integer,
    owner_type character varying(20),
    url text NOT NULL,
    unique_key character varying(10) NOT NULL,
    category character varying,
    use_count integer DEFAULT 0 NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: shortened_urls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shortened_urls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shortened_urls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shortened_urls_id_seq OWNED BY public.shortened_urls.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources (
    id integer NOT NULL,
    user_id integer,
    name character varying,
    slogan character varying,
    avatar character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    team_id integer,
    file character varying,
    archived integer DEFAULT 0,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sources_id_seq OWNED BY public.sources.id;


--
-- Name: tag_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_texts (
    id integer NOT NULL,
    text character varying NOT NULL,
    team_id integer NOT NULL,
    tags_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tag_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_texts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_texts_id_seq OWNED BY public.tag_texts.id;


--
-- Name: team_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_tasks (
    id integer NOT NULL,
    label character varying NOT NULL,
    task_type character varying NOT NULL,
    description text,
    options text,
    project_ids text,
    mapping text,
    required boolean DEFAULT false,
    team_id integer NOT NULL,
    "order" integer DEFAULT 0,
    associated_type character varying DEFAULT 'ProjectMedia'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    json_schema character varying,
    fieldset character varying DEFAULT ''::character varying NOT NULL,
    show_in_browser_extension boolean DEFAULT true NOT NULL,
    conditional_info text
);


--
-- Name: team_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_tasks_id_seq OWNED BY public.team_tasks.id;


--
-- Name: team_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_users (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying,
    status character varying DEFAULT 'member'::character varying,
    settings text,
    invited_by_id integer,
    invitation_token character varying,
    raw_invitation_token character varying,
    invitation_accepted_at timestamp without time zone,
    invitation_email character varying
);


--
-- Name: team_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_users_id_seq OWNED BY public.team_users.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying,
    logo character varying,
    private boolean DEFAULT true,
    archived integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description text,
    slug character varying,
    settings text,
    inactive boolean DEFAULT false,
    country character varying
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: tipline_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipline_subscriptions (
    id integer NOT NULL,
    uid character varying,
    language character varying,
    team_id integer,
    platform character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tipline_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipline_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipline_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipline_subscriptions_id_seq OWNED BY public.tipline_subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    login character varying DEFAULT ''::character varying NOT NULL,
    token character varying DEFAULT ''::character varying NOT NULL,
    email character varying,
    encrypted_password character varying DEFAULT ''::character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    image character varying,
    current_team_id integer,
    settings text,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    is_admin boolean DEFAULT false,
    cached_teams text,
    type character varying,
    api_key_id integer,
    source_id integer,
    unconfirmed_email character varying,
    current_project_id integer,
    is_active boolean DEFAULT true,
    invitation_token character varying,
    raw_invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying,
    last_accepted_terms_at timestamp without time zone,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    otp_backup_codes character varying[],
    "default" boolean DEFAULT false,
    completed_signup boolean DEFAULT true,
    last_active_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id character varying NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    object_changes text,
    created_at timestamp without time zone,
    meta text,
    event_type character varying,
    object_after text,
    associated_id integer,
    associated_type character varying,
    team_id integer
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: p0; Type: TABLE; Schema: versions_partitions; Owner: -
--

CREATE TABLE versions_partitions.p0 (
    CONSTRAINT p0_team_id_check CHECK ((team_id = 0))
)
INHERITS (public.versions);


--
-- Name: p1; Type: TABLE; Schema: versions_partitions; Owner: -
--

CREATE TABLE versions_partitions.p1 (
    CONSTRAINT p1_team_id_check CHECK ((team_id = 1))
)
INHERITS (public.versions);


--
-- Name: account_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_sources ALTER COLUMN id SET DEFAULT nextval('public.account_sources_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: annotations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations ALTER COLUMN id SET DEFAULT nextval('public.annotations_id_seq'::regclass);


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: bot_resources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_resources ALTER COLUMN id SET DEFAULT nextval('public.bot_resources_id_seq'::regclass);


--
-- Name: bounces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces ALTER COLUMN id SET DEFAULT nextval('public.bounces_id_seq'::regclass);


--
-- Name: dynamic_annotation_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_fields ALTER COLUMN id SET DEFAULT nextval('public.new_dynamic_annotation_fields_id_seq'::regclass);


--
-- Name: login_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_activities ALTER COLUMN id SET DEFAULT nextval('public.login_activities_id_seq'::regclass);


--
-- Name: medias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medias ALTER COLUMN id SET DEFAULT nextval('public.medias_id_seq'::regclass);


--
-- Name: pghero_query_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats ALTER COLUMN id SET DEFAULT nextval('public.pghero_query_stats_id_seq'::regclass);


--
-- Name: project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_groups ALTER COLUMN id SET DEFAULT nextval('public.project_groups_id_seq'::regclass);


--
-- Name: project_media_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_media_users ALTER COLUMN id SET DEFAULT nextval('public.project_media_users_id_seq'::regclass);


--
-- Name: project_medias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_medias ALTER COLUMN id SET DEFAULT nextval('public.project_medias_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships ALTER COLUMN id SET DEFAULT nextval('public.relationships_id_seq'::regclass);


--
-- Name: saved_searches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_searches ALTER COLUMN id SET DEFAULT nextval('public.saved_searches_id_seq'::regclass);


--
-- Name: shortened_urls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shortened_urls ALTER COLUMN id SET DEFAULT nextval('public.shortened_urls_id_seq'::regclass);


--
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- Name: tag_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_texts ALTER COLUMN id SET DEFAULT nextval('public.tag_texts_id_seq'::regclass);


--
-- Name: team_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_tasks ALTER COLUMN id SET DEFAULT nextval('public.team_tasks_id_seq'::regclass);


--
-- Name: team_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_users ALTER COLUMN id SET DEFAULT nextval('public.team_users_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: tipline_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipline_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.tipline_subscriptions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: p0 id; Type: DEFAULT; Schema: versions_partitions; Owner: -
--

ALTER TABLE ONLY versions_partitions.p0 ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: p1 id; Type: DEFAULT; Schema: versions_partitions; Owner: -
--

ALTER TABLE ONLY versions_partitions.p1 ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: account_sources account_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_sources
    ADD CONSTRAINT account_sources_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: annotations annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: bot_resources bot_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_resources
    ADD CONSTRAINT bot_resources_pkey PRIMARY KEY (id);


--
-- Name: bounces bounces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces
    ADD CONSTRAINT bounces_pkey PRIMARY KEY (id);


--
-- Name: dynamic_annotation_annotation_types dynamic_annotation_annotation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_annotation_types
    ADD CONSTRAINT dynamic_annotation_annotation_types_pkey PRIMARY KEY (annotation_type);


--
-- Name: dynamic_annotation_field_instances dynamic_annotation_field_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_field_instances
    ADD CONSTRAINT dynamic_annotation_field_instances_pkey PRIMARY KEY (name);


--
-- Name: dynamic_annotation_field_types dynamic_annotation_field_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_field_types
    ADD CONSTRAINT dynamic_annotation_field_types_pkey PRIMARY KEY (field_type);


--
-- Name: login_activities login_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_activities
    ADD CONSTRAINT login_activities_pkey PRIMARY KEY (id);


--
-- Name: medias medias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medias
    ADD CONSTRAINT medias_pkey PRIMARY KEY (id);


--
-- Name: dynamic_annotation_fields new_dynamic_annotation_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_fields
    ADD CONSTRAINT new_dynamic_annotation_fields_pkey PRIMARY KEY (id);


--
-- Name: pghero_query_stats pghero_query_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats
    ADD CONSTRAINT pghero_query_stats_pkey PRIMARY KEY (id);


--
-- Name: project_groups project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_groups
    ADD CONSTRAINT project_groups_pkey PRIMARY KEY (id);


--
-- Name: project_media_users project_media_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_media_users
    ADD CONSTRAINT project_media_users_pkey PRIMARY KEY (id);


--
-- Name: project_medias project_medias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_medias
    ADD CONSTRAINT project_medias_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: saved_searches saved_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_searches
    ADD CONSTRAINT saved_searches_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shortened_urls shortened_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shortened_urls
    ADD CONSTRAINT shortened_urls_pkey PRIMARY KEY (id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: tag_texts tag_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_texts
    ADD CONSTRAINT tag_texts_pkey PRIMARY KEY (id);


--
-- Name: team_tasks team_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_tasks
    ADD CONSTRAINT team_tasks_pkey PRIMARY KEY (id);


--
-- Name: team_users team_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_users
    ADD CONSTRAINT team_users_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tipline_subscriptions tipline_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipline_subscriptions
    ADD CONSTRAINT tipline_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: dynamic_annotation_fields_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dynamic_annotation_fields_value ON public.dynamic_annotation_fields USING btree (public.dynamic_annotation_fields_value(field_name, value)) WHERE ((field_name)::text = ANY ((ARRAY['external_id'::character varying, 'smooch_user_id'::character varying, 'verification_status_status'::character varying])::text[]));


--
-- Name: index_account_sources_on_account_id_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_sources_on_account_id_and_source_id ON public.account_sources USING btree (account_id, source_id);


--
-- Name: index_account_sources_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_sources_on_source_id ON public.account_sources USING btree (source_id);


--
-- Name: index_accounts_on_uid_and_provider_and_token_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_uid_and_provider_and_token_and_email ON public.accounts USING btree (uid, provider, token, email);


--
-- Name: index_accounts_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_url ON public.accounts USING btree (url);


--
-- Name: index_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_user_id ON public.accounts USING btree (user_id);


--
-- Name: index_annotation_type_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotation_type_order ON public.annotations USING btree (annotation_type);


--
-- Name: index_annotations_on_annotated_type_and_annotated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_annotated_type_and_annotated_id ON public.annotations USING btree (annotated_type, annotated_id);


--
-- Name: index_annotations_on_annotation_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_annotation_type ON public.annotations USING btree (annotation_type);


--
-- Name: index_assignments_on_assigned_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assigned_id ON public.assignments USING btree (assigned_id);


--
-- Name: index_assignments_on_assigned_id_and_assigned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assigned_id_and_assigned_type ON public.assignments USING btree (assigned_id, assigned_type);


--
-- Name: index_assignments_on_assigned_id_and_assigned_type_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_assigned_id_and_assigned_type_and_user_id ON public.assignments USING btree (assigned_id, assigned_type, user_id);


--
-- Name: index_assignments_on_assigned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assigned_type ON public.assignments USING btree (assigned_type);


--
-- Name: index_assignments_on_assigner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assigner_id ON public.assignments USING btree (assigner_id);


--
-- Name: index_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_user_id ON public.assignments USING btree (user_id);


--
-- Name: index_bot_resources_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bot_resources_on_team_id ON public.bot_resources USING btree (team_id);


--
-- Name: index_bot_resources_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bot_resources_on_uuid ON public.bot_resources USING btree (uuid);


--
-- Name: index_bounces_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bounces_on_email ON public.bounces USING btree (email);


--
-- Name: index_dynamic_annotation_annotation_types_on_json_schema; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_annotation_types_on_json_schema ON public.dynamic_annotation_annotation_types USING gin (json_schema);


--
-- Name: index_dynamic_annotation_fields_on_annotation_id_and_field_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_annotation_id_and_field_name ON public.dynamic_annotation_fields USING btree (annotation_id, field_name);


--
-- Name: index_dynamic_annotation_fields_on_field_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_field_type ON public.dynamic_annotation_fields USING btree (field_type);


--
-- Name: index_dynamic_annotation_fields_on_value_json; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_value_json ON public.dynamic_annotation_fields USING gin (value_json);


--
-- Name: index_login_activities_on_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_activities_on_identity ON public.login_activities USING btree (identity);


--
-- Name: index_login_activities_on_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_activities_on_ip ON public.login_activities USING btree (ip);


--
-- Name: index_medias_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_medias_on_url ON public.medias USING btree (url);


--
-- Name: index_pghero_query_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pghero_query_stats_on_database_and_captured_at ON public.pghero_query_stats USING btree (database, captured_at);


--
-- Name: index_project_groups_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_groups_on_team_id ON public.project_groups USING btree (team_id);


--
-- Name: index_project_media_users_on_project_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_media_users_on_project_media_id ON public.project_media_users USING btree (project_media_id);


--
-- Name: index_project_media_users_on_project_media_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_media_users_on_project_media_id_and_user_id ON public.project_media_users USING btree (project_media_id, user_id);


--
-- Name: index_project_media_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_media_users_on_user_id ON public.project_media_users USING btree (user_id);


--
-- Name: index_project_medias_on_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_channel ON public.project_medias USING btree (channel);


--
-- Name: index_project_medias_on_last_seen; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_last_seen ON public.project_medias USING btree (last_seen);


--
-- Name: index_project_medias_on_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_media_id ON public.project_medias USING btree (media_id);


--
-- Name: index_project_medias_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_project_id ON public.project_medias USING btree (project_id);


--
-- Name: index_project_medias_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_source_id ON public.project_medias USING btree (source_id);


--
-- Name: index_project_medias_on_team_id_and_archived_and_sources_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_team_id_and_archived_and_sources_count ON public.project_medias USING btree (team_id, archived, sources_count);


--
-- Name: index_project_medias_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_user_id ON public.project_medias USING btree (user_id);


--
-- Name: index_projects_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_id ON public.projects USING btree (id);


--
-- Name: index_projects_on_privacy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_privacy ON public.projects USING btree (privacy);


--
-- Name: index_projects_on_project_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_project_group_id ON public.projects USING btree (project_group_id);


--
-- Name: index_projects_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_team_id ON public.projects USING btree (team_id);


--
-- Name: index_projects_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_token ON public.projects USING btree (token);


--
-- Name: index_relationships_on_relationship_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relationships_on_relationship_type ON public.relationships USING btree (relationship_type);


--
-- Name: index_saved_searches_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_searches_on_team_id ON public.saved_searches USING btree (team_id);


--
-- Name: index_shortened_urls_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shortened_urls_on_category ON public.shortened_urls USING btree (category);


--
-- Name: index_shortened_urls_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shortened_urls_on_owner_id_and_owner_type ON public.shortened_urls USING btree (owner_id, owner_type);


--
-- Name: index_shortened_urls_on_unique_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shortened_urls_on_unique_key ON public.shortened_urls USING btree (unique_key);


--
-- Name: index_shortened_urls_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shortened_urls_on_url ON public.shortened_urls USING btree (url);


--
-- Name: index_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status ON public.dynamic_annotation_fields USING btree (value) WHERE ((field_name)::text = 'verification_status_status'::text);


--
-- Name: index_tag_texts_on_text_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_texts_on_text_and_team_id ON public.tag_texts USING btree (text, team_id);


--
-- Name: index_team_tasks_on_team_id_and_fieldset_and_associated_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_tasks_on_team_id_and_fieldset_and_associated_type ON public.team_tasks USING btree (team_id, fieldset, associated_type);


--
-- Name: index_team_users_on_team_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_users_on_team_id_and_user_id ON public.team_users USING btree (team_id, user_id);


--
-- Name: index_team_users_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_users_on_type ON public.team_users USING btree (type);


--
-- Name: index_team_users_on_user_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_users_on_user_id_and_team_id ON public.team_users USING btree (user_id, team_id);


--
-- Name: index_team_users_on_user_id_and_team_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_users_on_user_id_and_team_id_and_status ON public.team_users USING btree (user_id, team_id, status);


--
-- Name: index_teams_on_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_country ON public.teams USING btree (country);


--
-- Name: index_teams_on_inactive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_inactive ON public.teams USING btree (inactive);


--
-- Name: index_teams_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_slug ON public.teams USING btree (slug);


--
-- Name: index_tipline_subscriptions_on_language; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tipline_subscriptions_on_language ON public.tipline_subscriptions USING btree (language);


--
-- Name: index_tipline_subscriptions_on_language_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tipline_subscriptions_on_language_and_team_id ON public.tipline_subscriptions USING btree (language, team_id);


--
-- Name: index_tipline_subscriptions_on_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tipline_subscriptions_on_platform ON public.tipline_subscriptions USING btree (platform);


--
-- Name: index_tipline_subscriptions_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tipline_subscriptions_on_team_id ON public.tipline_subscriptions USING btree (team_id);


--
-- Name: index_tipline_subscriptions_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tipline_subscriptions_on_uid ON public.tipline_subscriptions USING btree (uid);


--
-- Name: index_tipline_subscriptions_on_uid_and_language_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tipline_subscriptions_on_uid_and_language_and_team_id ON public.tipline_subscriptions USING btree (uid, language, team_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_login ON public.users USING btree (login);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_source_id ON public.users USING btree (source_id);


--
-- Name: index_users_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_token ON public.users USING btree (token);


--
-- Name: index_users_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_type ON public.users USING btree (type);


--
-- Name: index_versions_on_associated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_associated_id ON public.versions USING btree (associated_id);


--
-- Name: index_versions_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_event_type ON public.versions USING btree (event_type);


--
-- Name: index_versions_on_item_type_and_item_id_and_whodunnit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id_and_whodunnit ON public.versions USING btree (item_type, item_id, whodunnit);


--
-- Name: index_versions_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_team_id ON public.versions USING btree (team_id);


--
-- Name: relationship_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX relationship_index ON public.relationships USING btree (source_id, target_id, relationship_type);


--
-- Name: task_fieldset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_fieldset ON public.annotations USING btree (public.task_fieldset((annotation_type)::text, data)) WHERE ((annotation_type)::text = 'task'::text);


--
-- Name: task_team_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_team_task_id ON public.annotations USING btree (public.task_team_task_id((annotation_type)::text, data)) WHERE ((annotation_type)::text = 'task'::text);


--
-- Name: unique_team_slugs; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_team_slugs ON public.teams USING btree (slug);


--
-- Name: item_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX item_p1 ON versions_partitions.p1 USING btree (item_type, item_id);


--
-- Name: version_annotation_type_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_annotation_type_p1 ON versions_partitions.p1 USING btree (public.version_annotation_type((event_type)::text, object_after));


--
-- Name: version_associated_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_associated_p1 ON versions_partitions.p1 USING btree (associated_type, associated_id);


--
-- Name: version_event_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_event_p1 ON versions_partitions.p1 USING btree (event);


--
-- Name: version_event_type_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_event_type_p1 ON versions_partitions.p1 USING btree (event_type);


--
-- Name: version_field_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_field_p1 ON versions_partitions.p1 USING btree (public.version_field_name((event_type)::text, object_after));


--
-- Name: version_team_id_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_team_id_p1 ON versions_partitions.p1 USING btree (team_id);


--
-- Name: version_whodunnit_p1; Type: INDEX; Schema: versions_partitions; Owner: -
--

CREATE INDEX version_whodunnit_p1 ON versions_partitions.p1 USING btree (whodunnit);


--
-- Name: versions versions_insert_redirector; Type: RULE; Schema: public; Owner: -
--

CREATE RULE versions_insert_redirector AS
    ON INSERT TO public.versions DO INSTEAD  SELECT public.always_fail_on_insert('versions'::text) AS always_fail_on_insert;


--
-- Name: p0 p0_team_id_fkey; Type: FK CONSTRAINT; Schema: versions_partitions; Owner: -
--

ALTER TABLE ONLY versions_partitions.p0
    ADD CONSTRAINT p0_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: p1 p1_team_id_fkey; Type: FK CONSTRAINT; Schema: versions_partitions; Owner: -
--

ALTER TABLE ONLY versions_partitions.p1
    ADD CONSTRAINT p1_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20150729232909'),
('20160203234652'),
('20160606003855'),
('20160613142614'),
('20160613174748'),
('20160613182506'),
('20160613183535'),
('20160613185048'),
('20160615183706'),
('20160615185336'),
('20160622182507'),
('20160630195945'),
('20160718072004'),
('20160718072536'),
('20160719180034'),
('20160803061918'),
('20160804064543'),
('20160808094036'),
('20160810100235'),
('20160810165248'),
('20160816225453'),
('20160817222619'),
('20160822140558'),
('20160822174902'),
('20160901035028'),
('20160910152705'),
('20160927082810'),
('20160927085541'),
('20161005065727'),
('20161005170145'),
('20161005170147'),
('20161012230605'),
('20161027180411'),
('20161029004335'),
('20161031195356'),
('20161104183828'),
('20161108182853'),
('20161108184312'),
('20161108185709'),
('20161117201803'),
('20161118184634'),
('20161122184954'),
('20161126044424'),
('20161218042414'),
('20161218051302'),
('20161226041556'),
('20170111175314'),
('20170111231958'),
('20170112234110'),
('20170119162024'),
('20170127210845'),
('20170131154821'),
('20170210165253'),
('20170210174412'),
('20170210175939'),
('20170210205259'),
('20170216223737'),
('20170223213437'),
('20170224222623'),
('20170224223650'),
('20170224223653'),
('20170226145445'),
('20170302215416'),
('20170306213714'),
('20170309024206'),
('20170309040021'),
('20170317192232'),
('20170322001743'),
('20170322002152'),
('20170322195431'),
('20170402202619'),
('20170402210950'),
('20170402214506'),
('20170402214846'),
('20170410121533'),
('20170412010401'),
('20170412012023'),
('20170421034336'),
('20170425175808'),
('20170430155754'),
('20170506181138'),
('20170506223918'),
('20170508161146'),
('20170508220654'),
('20170512020210'),
('20170512163626'),
('20170517192605'),
('20170529182930'),
('20170603160113'),
('20170612180953'),
('20170627181304'),
('20170627191706'),
('20170629211359'),
('20170706201604'),
('20170706214243'),
('20170712185149'),
('20170718125231'),
('20170718200922'),
('20170719212106'),
('20170720203304'),
('20170720211738'),
('20170721190857'),
('20170725185734'),
('20170726053947'),
('20170801063954'),
('20170816173001'),
('20170821195330'),
('20170904204026'),
('20171106203924'),
('20171107204751'),
('20171108003649'),
('20171113211004'),
('20171113215700'),
('20171117205707'),
('20171121005518'),
('20171214212740'),
('20180102112601'),
('20180115043720'),
('20180116203433'),
('20180123205909'),
('20180205143228'),
('20180206203438'),
('20180212111937'),
('20180214214744'),
('20180223015914'),
('20180301132955'),
('20180314190415'),
('20180318160110'),
('20180322175347'),
('20180326141314'),
('20180401070029'),
('20180401185519'),
('20180404113311'),
('20180405171209'),
('20180416053203'),
('20180419060237'),
('20180426011434'),
('20180504020804'),
('20180514082313'),
('20180517201143'),
('20180517201144'),
('20180524062932'),
('20180605032459'),
('20180606040953'),
('20180606040954'),
('20180613135905'),
('20180705222204'),
('20180717194300'),
('20180801185901'),
('20180801190425'),
('20180802003235'),
('20180815065738'),
('20180903163321'),
('20180904114156'),
('20180910184548'),
('20180911184548'),
('20180914000325'),
('20180918190441'),
('20180918215730'),
('20180919184524'),
('20180921220829'),
('20180926184218'),
('20180927063738'),
('20180928162406'),
('20181010190550'),
('20181012184401'),
('20181018200315'),
('20181023202534'),
('20181024185849'),
('20181030044637'),
('20181108195808'),
('20181109175559'),
('20181115054433'),
('20181115233534'),
('20181116045747'),
('20181123054313'),
('20181218131041'),
('20190107151222'),
('20190117155506'),
('20190121155306'),
('20190128175927'),
('20190128175928'),
('20190130163825'),
('20190206221728'),
('20190207043947'),
('20190214192347'),
('20190215171916'),
('20190301135948'),
('20190302041737'),
('20190315153834'),
('20190329051941'),
('20190329052146'),
('20190412212655'),
('20190416181753'),
('20190419234715'),
('20190424104015'),
('20190425145738'),
('20190426165520'),
('20190427170218'),
('20190428000310'),
('20190510015832'),
('20190520144348'),
('20190522170933'),
('20190522212356'),
('20190527151821'),
('20190529183942'),
('20190530165846'),
('20190607204754'),
('20190610145649'),
('20190620211111'),
('20190628033042'),
('20190628224004'),
('20190704204411'),
('20190711005115'),
('20190717173612'),
('20190807004123'),
('20190814135634'),
('20190820191732'),
('20190907205606'),
('20190910132515'),
('20190911165914'),
('20190911195420'),
('20190913032345'),
('20190917184041'),
('20190918120237'),
('20191011213030'),
('20191024222303'),
('20191028041312'),
('20191028195010'),
('20191106005542'),
('20191111234417'),
('20191112211345'),
('20191122163542'),
('20191204175804'),
('20191205063344'),
('20191212164640'),
('20191212174338'),
('20191212185909'),
('20191224210819'),
('20200110150530'),
('20200113215035'),
('20200113220747'),
('20200114130927'),
('20200115111003'),
('20200120003144'),
('20200123134804'),
('20200123215512'),
('20200204072809'),
('20200210192210'),
('20200211072540'),
('20200211170542'),
('20200211170601'),
('20200214205918'),
('20200214213447'),
('20200219182601'),
('20200223032114'),
('20200228153237'),
('20200303000130'),
('20200304163437'),
('20200309181011'),
('20200310214351'),
('20200310214352'),
('20200330042217'),
('20200330201229'),
('20200414191256'),
('20200416142458'),
('20200419002155'),
('20200422180433'),
('20200428183506'),
('20200430132539'),
('20200501031331'),
('20200505200635'),
('20200506192103'),
('20200506223124'),
('20200507083428'),
('20200514035745'),
('20200518065632'),
('20200521054352'),
('20200526005352'),
('20200527050224'),
('20200602075919'),
('20200602143208'),
('20200602160945'),
('20200604225850'),
('20200610190854'),
('20200613154036'),
('20200615141723'),
('20200619140416'),
('20200624170005'),
('20200706211437'),
('20200718213936'),
('20200721183110'),
('20200722191615'),
('20200723170546'),
('20200729202134'),
('20200730211448'),
('20200801201315'),
('20200801230948'),
('20200804202204'),
('20200804202431'),
('20200812210835'),
('20200812210836'),
('20200813175255'),
('20200830233935'),
('20200904013812'),
('20200912175326'),
('20200912183503'),
('20200923180915'),
('20200929232447'),
('20201001185829'),
('20201009155942'),
('20201016004453'),
('20201016152242'),
('20201020020524'),
('20201020034234'),
('20201021100409'),
('20201030175455'),
('20201031161040'),
('20201109160504'),
('20201113205207'),
('20201113220754'),
('20201115175212'),
('20201117131952'),
('20201120193355'),
('20201124120741'),
('20201124155201'),
('20201129032106'),
('20201129212613'),
('20201207042158'),
('20201207144205'),
('20201207144206'),
('20201218010536'),
('20210106063154'),
('20210110193931'),
('20210124161425'),
('20210204044237'),
('20210204213753'),
('20210210001913'),
('20210216033609'),
('20210301152540'),
('20210303070517'),
('20210305233641'),
('20210309061459'),
('20210309223958'),
('20210328051130'),
('20210331000200'),
('20210401215715'),
('20210402222705'),
('20210407060253'),
('20210408210408'),
('20210408225651'),
('20210422063657'),
('20210423014828'),
('20210428174627'),
('20210429205144'),
('20210429221257'),
('20210504180559'),
('20210504211958'),
('20210504211959'),
('20210520195307'),
('20210606165124'),
('20210610200336'),
('20210613204517'),
('20210616203935'),
('20210712214934'),
('20210719021924'),
('20210722004334'),
('20210727180610'),
('20210727214018'),
('20210802000606'),
('20210806201600'),
('20210806202205'),
('20210810163544'),
('20210812190835'),
('20210819130452'),
('20210827141808'),
('20210830012850'),
('20210901005937'),
('20210910230347'),
('20210925232613'),
('20211001184243'),
('20211007204934'),
('20211011172623'),
('20211014173355'),
('20211019121302'),
('20211114080408'),
('20211119174153');


