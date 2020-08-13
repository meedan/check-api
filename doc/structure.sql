--
-- PostgreSQL database dump
--

-- Dumped from database version 11.8 (Debian 11.8-1.pgdg90+1)
-- Dumped by pg_dump version 11.7 (Debian 11.7-0+deb10u1)

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
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id integer NOT NULL,
    assigned_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_type character varying,
    assigner_id integer
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
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id integer NOT NULL,
    team_id integer,
    location character varying,
    phone character varying,
    web character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


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
    value_json jsonb DEFAULT '{}'::jsonb,
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
    user_id integer,
    user_type character varying,
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
-- Name: project_media_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_media_projects (
    id integer NOT NULL,
    project_media_id integer,
    project_id integer
);


--
-- Name: project_media_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_media_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_media_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_media_projects_id_seq OWNED BY public.project_media_projects.id;


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
    archived boolean DEFAULT false,
    targets_count integer DEFAULT 0 NOT NULL,
    sources_count integer DEFAULT 0 NOT NULL,
    team_id integer,
    read boolean DEFAULT false NOT NULL
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
    archived boolean DEFAULT false,
    settings text,
    token character varying,
    assignments_count integer DEFAULT 0
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
    user_id integer
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
    archived boolean DEFAULT false,
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    json_schema character varying,
    "order" integer DEFAULT 0
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
    archived boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description text,
    slug character varying,
    settings text,
    inactive boolean DEFAULT false
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
    otp_backup_codes character varying[]
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
-- Name: bounces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces ALTER COLUMN id SET DEFAULT nextval('public.bounces_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


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
-- Name: project_media_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_media_projects ALTER COLUMN id SET DEFAULT nextval('public.project_media_projects_id_seq'::regclass);


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
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: bounces bounces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces
    ADD CONSTRAINT bounces_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


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
-- Name: project_media_projects project_media_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_media_projects
    ADD CONSTRAINT project_media_projects_pkey PRIMARY KEY (id);


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
-- Name: index_bounces_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bounces_on_email ON public.bounces USING btree (email);


--
-- Name: index_dynamic_annotation_annotation_types_on_json_schema; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_annotation_types_on_json_schema ON public.dynamic_annotation_annotation_types USING gin (json_schema);


--
-- Name: index_dynamic_annotation_fields_on_annotation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_annotation_id ON public.dynamic_annotation_fields USING btree (annotation_id);


--
-- Name: index_dynamic_annotation_fields_on_field_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_field_name ON public.dynamic_annotation_fields USING btree (field_name);


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
-- Name: index_medias_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medias_on_id ON public.medias USING btree (id);


--
-- Name: index_medias_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_medias_on_url ON public.medias USING btree (url);


--
-- Name: index_pghero_query_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pghero_query_stats_on_database_and_captured_at ON public.pghero_query_stats USING btree (database, captured_at);


--
-- Name: index_project_media_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_media_projects_on_project_id ON public.project_media_projects USING btree (project_id);


--
-- Name: index_project_media_projects_on_project_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_media_projects_on_project_media_id ON public.project_media_projects USING btree (project_media_id);


--
-- Name: index_project_media_projects_on_project_media_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_media_projects_on_project_media_id_and_project_id ON public.project_media_projects USING btree (project_media_id, project_id);


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
-- Name: index_project_medias_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_id ON public.project_medias USING btree (id);


--
-- Name: index_project_medias_on_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_media_id ON public.project_medias USING btree (media_id);


--
-- Name: index_project_medias_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_team_id ON public.project_medias USING btree (team_id);


--
-- Name: index_project_medias_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_user_id ON public.project_medias USING btree (user_id);


--
-- Name: index_projects_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_id ON public.projects USING btree (id);


--
-- Name: index_projects_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_team_id ON public.projects USING btree (team_id);


--
-- Name: index_projects_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_token ON public.projects USING btree (token);


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
-- Name: index_team_users_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_users_on_id ON public.team_users USING btree (id);


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
-- Name: index_teams_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_id ON public.teams USING btree (id);


--
-- Name: index_teams_on_inactive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_inactive ON public.teams USING btree (inactive);


--
-- Name: index_teams_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_slug ON public.teams USING btree (slug);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_id ON public.users USING btree (id);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


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
-- Name: task_team_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_team_task_id ON public.annotations USING btree (public.task_team_task_id((annotation_type)::text, data)) WHERE ((annotation_type)::text = 'task'::text);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


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

INSERT INTO schema_migrations (version) VALUES ('20150729232909');

INSERT INTO schema_migrations (version) VALUES ('20160203234652');

INSERT INTO schema_migrations (version) VALUES ('20160606003855');

INSERT INTO schema_migrations (version) VALUES ('20160613142614');

INSERT INTO schema_migrations (version) VALUES ('20160613174748');

INSERT INTO schema_migrations (version) VALUES ('20160613182506');

INSERT INTO schema_migrations (version) VALUES ('20160613183535');

INSERT INTO schema_migrations (version) VALUES ('20160613185048');

INSERT INTO schema_migrations (version) VALUES ('20160615183706');

INSERT INTO schema_migrations (version) VALUES ('20160615185336');

INSERT INTO schema_migrations (version) VALUES ('20160622182507');

INSERT INTO schema_migrations (version) VALUES ('20160630195945');

INSERT INTO schema_migrations (version) VALUES ('20160718072004');

INSERT INTO schema_migrations (version) VALUES ('20160718072536');

INSERT INTO schema_migrations (version) VALUES ('20160719180034');

INSERT INTO schema_migrations (version) VALUES ('20160803061918');

INSERT INTO schema_migrations (version) VALUES ('20160804064543');

INSERT INTO schema_migrations (version) VALUES ('20160808094036');

INSERT INTO schema_migrations (version) VALUES ('20160810100235');

INSERT INTO schema_migrations (version) VALUES ('20160810165248');

INSERT INTO schema_migrations (version) VALUES ('20160816225453');

INSERT INTO schema_migrations (version) VALUES ('20160817222619');

INSERT INTO schema_migrations (version) VALUES ('20160822140558');

INSERT INTO schema_migrations (version) VALUES ('20160822174902');

INSERT INTO schema_migrations (version) VALUES ('20160901035028');

INSERT INTO schema_migrations (version) VALUES ('20160910152705');

INSERT INTO schema_migrations (version) VALUES ('20160927082810');

INSERT INTO schema_migrations (version) VALUES ('20160927085541');

INSERT INTO schema_migrations (version) VALUES ('20161005065727');

INSERT INTO schema_migrations (version) VALUES ('20161005170145');

INSERT INTO schema_migrations (version) VALUES ('20161005170147');

INSERT INTO schema_migrations (version) VALUES ('20161012230605');

INSERT INTO schema_migrations (version) VALUES ('20161027180411');

INSERT INTO schema_migrations (version) VALUES ('20161029004335');

INSERT INTO schema_migrations (version) VALUES ('20161031195356');

INSERT INTO schema_migrations (version) VALUES ('20161104183828');

INSERT INTO schema_migrations (version) VALUES ('20161108182853');

INSERT INTO schema_migrations (version) VALUES ('20161108184312');

INSERT INTO schema_migrations (version) VALUES ('20161108185709');

INSERT INTO schema_migrations (version) VALUES ('20161117201803');

INSERT INTO schema_migrations (version) VALUES ('20161118184634');

INSERT INTO schema_migrations (version) VALUES ('20161122184954');

INSERT INTO schema_migrations (version) VALUES ('20161126044424');

INSERT INTO schema_migrations (version) VALUES ('20161218042414');

INSERT INTO schema_migrations (version) VALUES ('20161218051302');

INSERT INTO schema_migrations (version) VALUES ('20161226041556');

INSERT INTO schema_migrations (version) VALUES ('20170111175314');

INSERT INTO schema_migrations (version) VALUES ('20170111231958');

INSERT INTO schema_migrations (version) VALUES ('20170112234110');

INSERT INTO schema_migrations (version) VALUES ('20170119162024');

INSERT INTO schema_migrations (version) VALUES ('20170127210845');

INSERT INTO schema_migrations (version) VALUES ('20170131154821');

INSERT INTO schema_migrations (version) VALUES ('20170210165253');

INSERT INTO schema_migrations (version) VALUES ('20170210174412');

INSERT INTO schema_migrations (version) VALUES ('20170210175939');

INSERT INTO schema_migrations (version) VALUES ('20170210205259');

INSERT INTO schema_migrations (version) VALUES ('20170216223737');

INSERT INTO schema_migrations (version) VALUES ('20170223213437');

INSERT INTO schema_migrations (version) VALUES ('20170224222623');

INSERT INTO schema_migrations (version) VALUES ('20170224223650');

INSERT INTO schema_migrations (version) VALUES ('20170224223653');

INSERT INTO schema_migrations (version) VALUES ('20170226145445');

INSERT INTO schema_migrations (version) VALUES ('20170302215416');

INSERT INTO schema_migrations (version) VALUES ('20170306213714');

INSERT INTO schema_migrations (version) VALUES ('20170309024206');

INSERT INTO schema_migrations (version) VALUES ('20170309040021');

INSERT INTO schema_migrations (version) VALUES ('20170317192232');

INSERT INTO schema_migrations (version) VALUES ('20170322001743');

INSERT INTO schema_migrations (version) VALUES ('20170322002152');

INSERT INTO schema_migrations (version) VALUES ('20170322195431');

INSERT INTO schema_migrations (version) VALUES ('20170402202619');

INSERT INTO schema_migrations (version) VALUES ('20170402210950');

INSERT INTO schema_migrations (version) VALUES ('20170402214506');

INSERT INTO schema_migrations (version) VALUES ('20170402214846');

INSERT INTO schema_migrations (version) VALUES ('20170410121533');

INSERT INTO schema_migrations (version) VALUES ('20170412010401');

INSERT INTO schema_migrations (version) VALUES ('20170412012023');

INSERT INTO schema_migrations (version) VALUES ('20170421034336');

INSERT INTO schema_migrations (version) VALUES ('20170425175808');

INSERT INTO schema_migrations (version) VALUES ('20170430155754');

INSERT INTO schema_migrations (version) VALUES ('20170506181138');

INSERT INTO schema_migrations (version) VALUES ('20170506223918');

INSERT INTO schema_migrations (version) VALUES ('20170508161146');

INSERT INTO schema_migrations (version) VALUES ('20170508220654');

INSERT INTO schema_migrations (version) VALUES ('20170512020210');

INSERT INTO schema_migrations (version) VALUES ('20170512163626');

INSERT INTO schema_migrations (version) VALUES ('20170517192605');

INSERT INTO schema_migrations (version) VALUES ('20170529182930');

INSERT INTO schema_migrations (version) VALUES ('20170603160113');

INSERT INTO schema_migrations (version) VALUES ('20170612180953');

INSERT INTO schema_migrations (version) VALUES ('20170627181304');

INSERT INTO schema_migrations (version) VALUES ('20170627191706');

INSERT INTO schema_migrations (version) VALUES ('20170629211359');

INSERT INTO schema_migrations (version) VALUES ('20170706201604');

INSERT INTO schema_migrations (version) VALUES ('20170706214243');

INSERT INTO schema_migrations (version) VALUES ('20170712185149');

INSERT INTO schema_migrations (version) VALUES ('20170718125231');

INSERT INTO schema_migrations (version) VALUES ('20170718200922');

INSERT INTO schema_migrations (version) VALUES ('20170719212106');

INSERT INTO schema_migrations (version) VALUES ('20170720203304');

INSERT INTO schema_migrations (version) VALUES ('20170720211738');

INSERT INTO schema_migrations (version) VALUES ('20170721190857');

INSERT INTO schema_migrations (version) VALUES ('20170725185734');

INSERT INTO schema_migrations (version) VALUES ('20170726053947');

INSERT INTO schema_migrations (version) VALUES ('20170801063954');

INSERT INTO schema_migrations (version) VALUES ('20170816173001');

INSERT INTO schema_migrations (version) VALUES ('20170821195330');

INSERT INTO schema_migrations (version) VALUES ('20170904204026');

INSERT INTO schema_migrations (version) VALUES ('20171106203924');

INSERT INTO schema_migrations (version) VALUES ('20171107204751');

INSERT INTO schema_migrations (version) VALUES ('20171108003649');

INSERT INTO schema_migrations (version) VALUES ('20171113211004');

INSERT INTO schema_migrations (version) VALUES ('20171113215700');

INSERT INTO schema_migrations (version) VALUES ('20171117205707');

INSERT INTO schema_migrations (version) VALUES ('20171121005518');

INSERT INTO schema_migrations (version) VALUES ('20171214212740');

INSERT INTO schema_migrations (version) VALUES ('20180102112601');

INSERT INTO schema_migrations (version) VALUES ('20180115043720');

INSERT INTO schema_migrations (version) VALUES ('20180116203433');

INSERT INTO schema_migrations (version) VALUES ('20180123205909');

INSERT INTO schema_migrations (version) VALUES ('20180205143228');

INSERT INTO schema_migrations (version) VALUES ('20180206203438');

INSERT INTO schema_migrations (version) VALUES ('20180212111937');

INSERT INTO schema_migrations (version) VALUES ('20180214214744');

INSERT INTO schema_migrations (version) VALUES ('20180223015914');

INSERT INTO schema_migrations (version) VALUES ('20180301132955');

INSERT INTO schema_migrations (version) VALUES ('20180314190415');

INSERT INTO schema_migrations (version) VALUES ('20180318160110');

INSERT INTO schema_migrations (version) VALUES ('20180322175347');

INSERT INTO schema_migrations (version) VALUES ('20180326141314');

INSERT INTO schema_migrations (version) VALUES ('20180401070029');

INSERT INTO schema_migrations (version) VALUES ('20180401185519');

INSERT INTO schema_migrations (version) VALUES ('20180404113311');

INSERT INTO schema_migrations (version) VALUES ('20180405171209');

INSERT INTO schema_migrations (version) VALUES ('20180416053203');

INSERT INTO schema_migrations (version) VALUES ('20180419060237');

INSERT INTO schema_migrations (version) VALUES ('20180426011434');

INSERT INTO schema_migrations (version) VALUES ('20180504020804');

INSERT INTO schema_migrations (version) VALUES ('20180514082313');

INSERT INTO schema_migrations (version) VALUES ('20180517201143');

INSERT INTO schema_migrations (version) VALUES ('20180517201144');

INSERT INTO schema_migrations (version) VALUES ('20180524062932');

INSERT INTO schema_migrations (version) VALUES ('20180605032459');

INSERT INTO schema_migrations (version) VALUES ('20180606040953');

INSERT INTO schema_migrations (version) VALUES ('20180606040954');

INSERT INTO schema_migrations (version) VALUES ('20180613135905');

INSERT INTO schema_migrations (version) VALUES ('20180705222204');

INSERT INTO schema_migrations (version) VALUES ('20180717194300');

INSERT INTO schema_migrations (version) VALUES ('20180801185901');

INSERT INTO schema_migrations (version) VALUES ('20180801190425');

INSERT INTO schema_migrations (version) VALUES ('20180802003235');

INSERT INTO schema_migrations (version) VALUES ('20180815065738');

INSERT INTO schema_migrations (version) VALUES ('20180903163321');

INSERT INTO schema_migrations (version) VALUES ('20180904114156');

INSERT INTO schema_migrations (version) VALUES ('20180910184548');

INSERT INTO schema_migrations (version) VALUES ('20180911184548');

INSERT INTO schema_migrations (version) VALUES ('20180914000325');

INSERT INTO schema_migrations (version) VALUES ('20180918190441');

INSERT INTO schema_migrations (version) VALUES ('20180918215730');

INSERT INTO schema_migrations (version) VALUES ('20180919184524');

INSERT INTO schema_migrations (version) VALUES ('20180921220829');

INSERT INTO schema_migrations (version) VALUES ('20180926184218');

INSERT INTO schema_migrations (version) VALUES ('20180927063738');

INSERT INTO schema_migrations (version) VALUES ('20180928162406');

INSERT INTO schema_migrations (version) VALUES ('20181010190550');

INSERT INTO schema_migrations (version) VALUES ('20181012184401');

INSERT INTO schema_migrations (version) VALUES ('20181018200315');

INSERT INTO schema_migrations (version) VALUES ('20181023202534');

INSERT INTO schema_migrations (version) VALUES ('20181024185849');

INSERT INTO schema_migrations (version) VALUES ('20181030044637');

INSERT INTO schema_migrations (version) VALUES ('20181108195808');

INSERT INTO schema_migrations (version) VALUES ('20181109175559');

INSERT INTO schema_migrations (version) VALUES ('20181115054433');

INSERT INTO schema_migrations (version) VALUES ('20181115233534');

INSERT INTO schema_migrations (version) VALUES ('20181116045747');

INSERT INTO schema_migrations (version) VALUES ('20181123054313');

INSERT INTO schema_migrations (version) VALUES ('20181218131041');

INSERT INTO schema_migrations (version) VALUES ('20190107151222');

INSERT INTO schema_migrations (version) VALUES ('20190117155506');

INSERT INTO schema_migrations (version) VALUES ('20190121155306');

INSERT INTO schema_migrations (version) VALUES ('20190128175927');

INSERT INTO schema_migrations (version) VALUES ('20190128175928');

INSERT INTO schema_migrations (version) VALUES ('20190130163825');

INSERT INTO schema_migrations (version) VALUES ('20190206221728');

INSERT INTO schema_migrations (version) VALUES ('20190207043947');

INSERT INTO schema_migrations (version) VALUES ('20190214192347');

INSERT INTO schema_migrations (version) VALUES ('20190215171916');

INSERT INTO schema_migrations (version) VALUES ('20190301135948');

INSERT INTO schema_migrations (version) VALUES ('20190302041737');

INSERT INTO schema_migrations (version) VALUES ('20190315153834');

INSERT INTO schema_migrations (version) VALUES ('20190329051941');

INSERT INTO schema_migrations (version) VALUES ('20190329052146');

INSERT INTO schema_migrations (version) VALUES ('20190412212655');

INSERT INTO schema_migrations (version) VALUES ('20190416181753');

INSERT INTO schema_migrations (version) VALUES ('20190419234715');

INSERT INTO schema_migrations (version) VALUES ('20190424104015');

INSERT INTO schema_migrations (version) VALUES ('20190425145738');

INSERT INTO schema_migrations (version) VALUES ('20190426165520');

INSERT INTO schema_migrations (version) VALUES ('20190427170218');

INSERT INTO schema_migrations (version) VALUES ('20190428000310');

INSERT INTO schema_migrations (version) VALUES ('20190510015832');

INSERT INTO schema_migrations (version) VALUES ('20190520144348');

INSERT INTO schema_migrations (version) VALUES ('20190522170933');

INSERT INTO schema_migrations (version) VALUES ('20190522212356');

INSERT INTO schema_migrations (version) VALUES ('20190527151821');

INSERT INTO schema_migrations (version) VALUES ('20190529183942');

INSERT INTO schema_migrations (version) VALUES ('20190530165846');

INSERT INTO schema_migrations (version) VALUES ('20190607204754');

INSERT INTO schema_migrations (version) VALUES ('20190610145649');

INSERT INTO schema_migrations (version) VALUES ('20190620211111');

INSERT INTO schema_migrations (version) VALUES ('20190628033042');

INSERT INTO schema_migrations (version) VALUES ('20190628224004');

INSERT INTO schema_migrations (version) VALUES ('20190704204411');

INSERT INTO schema_migrations (version) VALUES ('20190711005115');

INSERT INTO schema_migrations (version) VALUES ('20190717173612');

INSERT INTO schema_migrations (version) VALUES ('20190807004123');

INSERT INTO schema_migrations (version) VALUES ('20190814135634');

INSERT INTO schema_migrations (version) VALUES ('20190820191732');

INSERT INTO schema_migrations (version) VALUES ('20190907205606');

INSERT INTO schema_migrations (version) VALUES ('20190910132515');

INSERT INTO schema_migrations (version) VALUES ('20190911165914');

INSERT INTO schema_migrations (version) VALUES ('20190911195420');

INSERT INTO schema_migrations (version) VALUES ('20190913032345');

INSERT INTO schema_migrations (version) VALUES ('20190917184041');

INSERT INTO schema_migrations (version) VALUES ('20190918120237');

INSERT INTO schema_migrations (version) VALUES ('20191011213030');

INSERT INTO schema_migrations (version) VALUES ('20191024222303');

INSERT INTO schema_migrations (version) VALUES ('20191028041312');

INSERT INTO schema_migrations (version) VALUES ('20191028195010');

INSERT INTO schema_migrations (version) VALUES ('20191106005542');

INSERT INTO schema_migrations (version) VALUES ('20191111234417');

INSERT INTO schema_migrations (version) VALUES ('20191112211345');

INSERT INTO schema_migrations (version) VALUES ('20191122163542');

INSERT INTO schema_migrations (version) VALUES ('20191204175804');

INSERT INTO schema_migrations (version) VALUES ('20191205063344');

INSERT INTO schema_migrations (version) VALUES ('20191212164640');

INSERT INTO schema_migrations (version) VALUES ('20191212174338');

INSERT INTO schema_migrations (version) VALUES ('20191212185909');

INSERT INTO schema_migrations (version) VALUES ('20191224210446');

INSERT INTO schema_migrations (version) VALUES ('20191224210819');

INSERT INTO schema_migrations (version) VALUES ('20191224225836');

INSERT INTO schema_migrations (version) VALUES ('20200110150530');

INSERT INTO schema_migrations (version) VALUES ('20200113215035');

INSERT INTO schema_migrations (version) VALUES ('20200113220747');

INSERT INTO schema_migrations (version) VALUES ('20200114130927');

INSERT INTO schema_migrations (version) VALUES ('20200115111003');

INSERT INTO schema_migrations (version) VALUES ('20200120003144');

INSERT INTO schema_migrations (version) VALUES ('20200123134804');

INSERT INTO schema_migrations (version) VALUES ('20200123215512');

INSERT INTO schema_migrations (version) VALUES ('20200204072809');

INSERT INTO schema_migrations (version) VALUES ('20200210192210');

INSERT INTO schema_migrations (version) VALUES ('20200211072540');

INSERT INTO schema_migrations (version) VALUES ('20200211170542');

INSERT INTO schema_migrations (version) VALUES ('20200211170601');

INSERT INTO schema_migrations (version) VALUES ('20200214205918');

INSERT INTO schema_migrations (version) VALUES ('20200214213447');

INSERT INTO schema_migrations (version) VALUES ('20200219182601');

INSERT INTO schema_migrations (version) VALUES ('20200223032114');

INSERT INTO schema_migrations (version) VALUES ('20200228153237');

INSERT INTO schema_migrations (version) VALUES ('20200303000130');

INSERT INTO schema_migrations (version) VALUES ('20200304163437');

INSERT INTO schema_migrations (version) VALUES ('20200309181011');

INSERT INTO schema_migrations (version) VALUES ('20200310214351');

INSERT INTO schema_migrations (version) VALUES ('20200310214352');

INSERT INTO schema_migrations (version) VALUES ('20200330042217');

INSERT INTO schema_migrations (version) VALUES ('20200330201229');

INSERT INTO schema_migrations (version) VALUES ('20200414191256');

INSERT INTO schema_migrations (version) VALUES ('20200416142458');

INSERT INTO schema_migrations (version) VALUES ('20200419002155');

INSERT INTO schema_migrations (version) VALUES ('20200422180433');

INSERT INTO schema_migrations (version) VALUES ('20200428183506');

INSERT INTO schema_migrations (version) VALUES ('20200430132539');

INSERT INTO schema_migrations (version) VALUES ('20200501031331');

INSERT INTO schema_migrations (version) VALUES ('20200505200635');

INSERT INTO schema_migrations (version) VALUES ('20200506192103');

INSERT INTO schema_migrations (version) VALUES ('20200506223124');

INSERT INTO schema_migrations (version) VALUES ('20200507083428');

INSERT INTO schema_migrations (version) VALUES ('20200514035745');

INSERT INTO schema_migrations (version) VALUES ('20200518065632');

INSERT INTO schema_migrations (version) VALUES ('20200521054352');

INSERT INTO schema_migrations (version) VALUES ('20200526005352');

INSERT INTO schema_migrations (version) VALUES ('20200527050224');

INSERT INTO schema_migrations (version) VALUES ('20200602075919');

INSERT INTO schema_migrations (version) VALUES ('20200602143208');

INSERT INTO schema_migrations (version) VALUES ('20200602160945');

INSERT INTO schema_migrations (version) VALUES ('20200604225850');

INSERT INTO schema_migrations (version) VALUES ('20200610190854');

INSERT INTO schema_migrations (version) VALUES ('20200613154036');

INSERT INTO schema_migrations (version) VALUES ('20200615141723');

INSERT INTO schema_migrations (version) VALUES ('20200617191948');

INSERT INTO schema_migrations (version) VALUES ('20200619140416');

INSERT INTO schema_migrations (version) VALUES ('20200624170005');

INSERT INTO schema_migrations (version) VALUES ('20200706211437');

INSERT INTO schema_migrations (version) VALUES ('20200718213936');

INSERT INTO schema_migrations (version) VALUES ('20200721183110');

INSERT INTO schema_migrations (version) VALUES ('20200722191615');

INSERT INTO schema_migrations (version) VALUES ('20200723170546');

INSERT INTO schema_migrations (version) VALUES ('20200729202134');

INSERT INTO schema_migrations (version) VALUES ('20200730211448');

INSERT INTO schema_migrations (version) VALUES ('20200801201315');

INSERT INTO schema_migrations (version) VALUES ('20200801230948');

INSERT INTO schema_migrations (version) VALUES ('20200804202204');

INSERT INTO schema_migrations (version) VALUES ('20200804202431');

