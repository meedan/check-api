--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.11
-- Dumped by pg_dump version 9.6.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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
-- Name: bot_alegres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_alegres (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar character varying
);


--
-- Name: bot_alegres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_alegres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_alegres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_alegres_id_seq OWNED BY public.bot_alegres.id;


--
-- Name: bot_bots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_bots (
    id integer NOT NULL,
    name character varying,
    avatar character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_bots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_bots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_bots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_bots_id_seq OWNED BY public.bot_bots.id;


--
-- Name: bot_bridge_readers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_bridge_readers (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_bridge_readers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_bridge_readers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_bridge_readers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_bridge_readers_id_seq OWNED BY public.bot_bridge_readers.id;


--
-- Name: bot_facebooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_facebooks (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_facebooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_facebooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_facebooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_facebooks_id_seq OWNED BY public.bot_facebooks.id;


--
-- Name: bot_slacks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_slacks (
    id integer NOT NULL,
    name character varying,
    settings text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_slacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_slacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_slacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_slacks_id_seq OWNED BY public.bot_slacks.id;


--
-- Name: bot_twitters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_twitters (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_twitters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_twitters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_twitters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_twitters_id_seq OWNED BY public.bot_twitters.id;


--
-- Name: bot_vibers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_vibers (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_vibers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_vibers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_vibers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_vibers_id_seq OWNED BY public.bot_vibers.id;


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
-- Name: claim_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claim_sources (
    id integer NOT NULL,
    media_id integer,
    source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claim_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claim_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claim_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claim_sources_id_seq OWNED BY public.claim_sources.id;


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
    singleton boolean DEFAULT true
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_value character varying
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    value_json jsonb DEFAULT '{}'::jsonb
);


--
-- Name: dynamic_annotation_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dynamic_annotation_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_annotation_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dynamic_annotation_fields_id_seq OWNED BY public.dynamic_annotation_fields.id;


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
-- Name: project_medias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_medias (
    id integer NOT NULL,
    project_id integer,
    media_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    cached_annotations_count integer DEFAULT 0,
    archived boolean DEFAULT false,
    targets_count integer DEFAULT 0 NOT NULL,
    sources_count integer DEFAULT 0 NOT NULL,
    inactive boolean DEFAULT false
);


--
-- Name: project_medias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_medias_id_seq
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
-- Name: project_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_sources (
    id integer NOT NULL,
    project_id integer,
    source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    cached_annotations_count integer DEFAULT 0
);


--
-- Name: project_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_sources_id_seq OWNED BY public.project_sources.id;


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
    teamwide boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tag_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_texts_id_seq
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
-- Name: team_bot_installations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_bot_installations (
    id integer NOT NULL,
    team_id integer,
    team_bot_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    settings text
);


--
-- Name: team_bot_installations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_bot_installations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_bot_installations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_bot_installations_id_seq OWNED BY public.team_bot_installations.id;


--
-- Name: team_bots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_bots (
    id integer NOT NULL,
    identifier character varying NOT NULL,
    name character varying NOT NULL,
    description character varying,
    file character varying,
    request_url character varying NOT NULL,
    role character varying DEFAULT 'editor'::character varying NOT NULL,
    version character varying DEFAULT '0.0.1'::character varying,
    source_code_url character varying,
    bot_user_id integer,
    team_author_id integer,
    events text,
    approved boolean DEFAULT false,
    limited boolean DEFAULT false,
    last_called_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    settings text
);


--
-- Name: team_bots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_bots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_bots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_bots_id_seq OWNED BY public.team_bots.id;


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
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_tasks_id_seq
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying,
    status character varying DEFAULT 'member'::character varying,
    invited_by_id integer,
    invitation_token character varying,
    raw_invitation_token character varying,
    invitation_accepted_at timestamp without time zone
);


--
-- Name: team_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_users_id_seq
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
    limits text,
    inactive boolean DEFAULT false
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
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
    last_accepted_terms_at timestamp without time zone,
    invitation_token character varying,
    raw_invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
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
    associated_type character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
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
-- Name: bot_alegres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_alegres ALTER COLUMN id SET DEFAULT nextval('public.bot_alegres_id_seq'::regclass);


--
-- Name: bot_bots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_bots ALTER COLUMN id SET DEFAULT nextval('public.bot_bots_id_seq'::regclass);


--
-- Name: bot_bridge_readers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_bridge_readers ALTER COLUMN id SET DEFAULT nextval('public.bot_bridge_readers_id_seq'::regclass);


--
-- Name: bot_facebooks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_facebooks ALTER COLUMN id SET DEFAULT nextval('public.bot_facebooks_id_seq'::regclass);


--
-- Name: bot_slacks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_slacks ALTER COLUMN id SET DEFAULT nextval('public.bot_slacks_id_seq'::regclass);


--
-- Name: bot_twitters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_twitters ALTER COLUMN id SET DEFAULT nextval('public.bot_twitters_id_seq'::regclass);


--
-- Name: bot_vibers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_vibers ALTER COLUMN id SET DEFAULT nextval('public.bot_vibers_id_seq'::regclass);


--
-- Name: bounces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces ALTER COLUMN id SET DEFAULT nextval('public.bounces_id_seq'::regclass);


--
-- Name: claim_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claim_sources ALTER COLUMN id SET DEFAULT nextval('public.claim_sources_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: dynamic_annotation_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_fields ALTER COLUMN id SET DEFAULT nextval('public.dynamic_annotation_fields_id_seq'::regclass);


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
-- Name: project_medias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_medias ALTER COLUMN id SET DEFAULT nextval('public.project_medias_id_seq'::regclass);


--
-- Name: project_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_sources ALTER COLUMN id SET DEFAULT nextval('public.project_sources_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships ALTER COLUMN id SET DEFAULT nextval('public.relationships_id_seq'::regclass);


--
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- Name: tag_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_texts ALTER COLUMN id SET DEFAULT nextval('public.tag_texts_id_seq'::regclass);


--
-- Name: team_bot_installations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_bot_installations ALTER COLUMN id SET DEFAULT nextval('public.team_bot_installations_id_seq'::regclass);


--
-- Name: team_bots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_bots ALTER COLUMN id SET DEFAULT nextval('public.team_bots_id_seq'::regclass);


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
-- Name: bot_alegres bot_alegres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_alegres
    ADD CONSTRAINT bot_alegres_pkey PRIMARY KEY (id);


--
-- Name: bot_bots bot_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_bots
    ADD CONSTRAINT bot_bots_pkey PRIMARY KEY (id);


--
-- Name: bot_bridge_readers bot_bridge_readers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_bridge_readers
    ADD CONSTRAINT bot_bridge_readers_pkey PRIMARY KEY (id);


--
-- Name: bot_facebooks bot_facebooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_facebooks
    ADD CONSTRAINT bot_facebooks_pkey PRIMARY KEY (id);


--
-- Name: bot_slacks bot_slacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_slacks
    ADD CONSTRAINT bot_slacks_pkey PRIMARY KEY (id);


--
-- Name: bot_twitters bot_twitters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_twitters
    ADD CONSTRAINT bot_twitters_pkey PRIMARY KEY (id);


--
-- Name: bot_vibers bot_vibers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_vibers
    ADD CONSTRAINT bot_vibers_pkey PRIMARY KEY (id);


--
-- Name: bounces bounces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bounces
    ADD CONSTRAINT bounces_pkey PRIMARY KEY (id);


--
-- Name: claim_sources claim_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claim_sources
    ADD CONSTRAINT claim_sources_pkey PRIMARY KEY (id);


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
-- Name: dynamic_annotation_fields dynamic_annotation_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_annotation_fields
    ADD CONSTRAINT dynamic_annotation_fields_pkey PRIMARY KEY (id);


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
-- Name: pghero_query_stats pghero_query_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats
    ADD CONSTRAINT pghero_query_stats_pkey PRIMARY KEY (id);


--
-- Name: project_medias project_medias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_medias
    ADD CONSTRAINT project_medias_pkey PRIMARY KEY (id);


--
-- Name: project_sources project_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_sources
    ADD CONSTRAINT project_sources_pkey PRIMARY KEY (id);


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
-- Name: team_bot_installations team_bot_installations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_bot_installations
    ADD CONSTRAINT team_bot_installations_pkey PRIMARY KEY (id);


--
-- Name: team_bots team_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_bots
    ADD CONSTRAINT team_bots_pkey PRIMARY KEY (id);


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
-- Name: index_claim_sources_on_media_id_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_claim_sources_on_media_id_and_source_id ON public.claim_sources USING btree (media_id, source_id);


--
-- Name: index_dynamic_annotation_fields_on_annotation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_annotation_fields_on_annotation_id ON public.dynamic_annotation_fields USING btree (annotation_id);


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
-- Name: index_project_medias_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_id ON public.project_medias USING btree (id);


--
-- Name: index_project_medias_on_inactive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_inactive ON public.project_medias USING btree (inactive);


--
-- Name: index_project_medias_on_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_medias_on_media_id ON public.project_medias USING btree (media_id);


--
-- Name: index_project_medias_on_project_id_and_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_medias_on_project_id_and_media_id ON public.project_medias USING btree (project_id, media_id);


--
-- Name: index_project_sources_on_project_id_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_sources_on_project_id_and_source_id ON public.project_sources USING btree (project_id, source_id);


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
-- Name: index_tag_texts_on_text_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_texts_on_text_and_team_id ON public.tag_texts USING btree (text, team_id);


--
-- Name: index_team_bot_installations_on_team_bot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_bot_installations_on_team_bot_id ON public.team_bot_installations USING btree (team_bot_id);


--
-- Name: index_team_bot_installations_on_team_id_and_team_bot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_bot_installations_on_team_id_and_team_bot_id ON public.team_bot_installations USING btree (team_id, team_bot_id);


--
-- Name: index_team_bots_on_approved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_bots_on_approved ON public.team_bots USING btree (approved);


--
-- Name: index_team_bots_on_bot_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_bots_on_bot_user_id ON public.team_bots USING btree (bot_user_id);


--
-- Name: index_team_bots_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_bots_on_identifier ON public.team_bots USING btree (identifier);


--
-- Name: index_team_bots_on_team_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_bots_on_team_author_id ON public.team_bots USING btree (team_author_id);


--
-- Name: index_team_users_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_users_on_id ON public.team_users USING btree (id);


--
-- Name: index_team_users_on_team_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_users_on_team_id_and_user_id ON public.team_users USING btree (team_id, user_id);


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
-- Name: index_versions_on_associated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_associated_id ON public.versions USING btree (associated_id);


--
-- Name: index_versions_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_event_type ON public.versions USING btree (event_type);


--
-- Name: relationship_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX relationship_index ON public.relationships USING btree (source_id, target_id, relationship_type);


--
-- Name: translation_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX translation_request_id ON public.dynamic_annotation_fields USING btree (value) WHERE ((field_name)::text = 'translation_request_id'::text);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: unique_team_slugs; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_team_slugs ON public.teams USING btree (slug);


--
-- Name: accounts fk_rails_16c8fecc67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_16c8fecc67 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: project_medias fk_rails_747821fe70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_medias
    ADD CONSTRAINT fk_rails_747821fe70 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_869bf2c95b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_869bf2c95b FOREIGN KEY (source_id) REFERENCES public.sources(id);


--
-- Name: sources fk_rails_8907b64d78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT fk_rails_8907b64d78 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: project_sources fk_rails_a45f01cbd6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_sources
    ADD CONSTRAINT fk_rails_a45f01cbd6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

