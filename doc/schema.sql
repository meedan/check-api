--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 11.2 (Ubuntu 11.2-1.pgdg16.04+1)

-- Started on 2019-04-16 12:28:00 PDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 232 (class 1259 OID 16793)
-- Name: account_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_sources (
    id integer NOT NULL,
    account_id integer,
    source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.account_sources OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16791)
-- Name: account_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_sources_id_seq OWNER TO postgres;

--
-- TOC entry 2543 (class 0 OID 0)
-- Dependencies: 231
-- Name: account_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_sources_id_seq OWNED BY public.account_sources.id;


--
-- TOC entry 193 (class 1259 OID 16441)
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.accounts OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 16439)
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO postgres;

--
-- TOC entry 2544 (class 0 OID 0)
-- Dependencies: 192
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- TOC entry 215 (class 1259 OID 16625)
-- Name: annotations; Type: TABLE; Schema: public; Owner: postgres
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
    locked boolean DEFAULT false
);


ALTER TABLE public.annotations OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16623)
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.annotations_id_seq OWNER TO postgres;

--
-- TOC entry 2545 (class 0 OID 0)
-- Dependencies: 214
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.annotations_id_seq OWNED BY public.annotations.id;


--
-- TOC entry 187 (class 1259 OID 16394)
-- Name: api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    access_token character varying DEFAULT ''::character varying NOT NULL,
    expire_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    application character varying
);


ALTER TABLE public.api_keys OWNER TO postgres;

--
-- TOC entry 186 (class 1259 OID 16392)
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_keys_id_seq OWNER TO postgres;

--
-- TOC entry 2546 (class 0 OID 0)
-- Dependencies: 186
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- TOC entry 250 (class 1259 OID 17028)
-- Name: assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignments (
    id integer NOT NULL,
    assigned_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_type character varying
);


ALTER TABLE public.assignments OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 17026)
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assignments_id_seq OWNER TO postgres;

--
-- TOC entry 2547 (class 0 OID 0)
-- Dependencies: 249
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- TOC entry 222 (class 1259 OID 16698)
-- Name: bot_alegres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_alegres (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar character varying
);


ALTER TABLE public.bot_alegres OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16696)
-- Name: bot_alegres_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_alegres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_alegres_id_seq OWNER TO postgres;

--
-- TOC entry 2548 (class 0 OID 0)
-- Dependencies: 221
-- Name: bot_alegres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_alegres_id_seq OWNED BY public.bot_alegres.id;


--
-- TOC entry 211 (class 1259 OID 16588)
-- Name: bot_bots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_bots (
    id integer NOT NULL,
    name character varying,
    avatar character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_bots OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16586)
-- Name: bot_bots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_bots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_bots_id_seq OWNER TO postgres;

--
-- TOC entry 2549 (class 0 OID 0)
-- Dependencies: 210
-- Name: bot_bots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_bots_id_seq OWNED BY public.bot_bots.id;


--
-- TOC entry 236 (class 1259 OID 16908)
-- Name: bot_bridge_readers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_bridge_readers (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_bridge_readers OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16906)
-- Name: bot_bridge_readers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_bridge_readers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_bridge_readers_id_seq OWNER TO postgres;

--
-- TOC entry 2550 (class 0 OID 0)
-- Dependencies: 235
-- Name: bot_bridge_readers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_bridge_readers_id_seq OWNED BY public.bot_bridge_readers.id;


--
-- TOC entry 228 (class 1259 OID 16744)
-- Name: bot_facebooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_facebooks (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_facebooks OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16742)
-- Name: bot_facebooks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_facebooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_facebooks_id_seq OWNER TO postgres;

--
-- TOC entry 2551 (class 0 OID 0)
-- Dependencies: 227
-- Name: bot_facebooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_facebooks_id_seq OWNED BY public.bot_facebooks.id;


--
-- TOC entry 230 (class 1259 OID 16763)
-- Name: bot_slacks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_slacks (
    id integer NOT NULL,
    name character varying,
    settings text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_slacks OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16761)
-- Name: bot_slacks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_slacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_slacks_id_seq OWNER TO postgres;

--
-- TOC entry 2552 (class 0 OID 0)
-- Dependencies: 229
-- Name: bot_slacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_slacks_id_seq OWNED BY public.bot_slacks.id;


--
-- TOC entry 226 (class 1259 OID 16733)
-- Name: bot_twitters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_twitters (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_twitters OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16731)
-- Name: bot_twitters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_twitters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_twitters_id_seq OWNER TO postgres;

--
-- TOC entry 2553 (class 0 OID 0)
-- Dependencies: 225
-- Name: bot_twitters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_twitters_id_seq OWNED BY public.bot_twitters.id;


--
-- TOC entry 224 (class 1259 OID 16720)
-- Name: bot_vibers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bot_vibers (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bot_vibers OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16718)
-- Name: bot_vibers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bot_vibers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bot_vibers_id_seq OWNER TO postgres;

--
-- TOC entry 2554 (class 0 OID 0)
-- Dependencies: 223
-- Name: bot_vibers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bot_vibers_id_seq OWNED BY public.bot_vibers.id;


--
-- TOC entry 213 (class 1259 OID 16612)
-- Name: bounces; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bounces (
    id integer NOT NULL,
    email character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.bounces OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16610)
-- Name: bounces_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bounces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bounces_id_seq OWNER TO postgres;

--
-- TOC entry 2555 (class 0 OID 0)
-- Dependencies: 212
-- Name: bounces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bounces_id_seq OWNED BY public.bounces.id;


--
-- TOC entry 234 (class 1259 OID 16836)
-- Name: claim_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.claim_sources (
    id integer NOT NULL,
    media_id integer,
    source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.claim_sources OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16834)
-- Name: claim_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.claim_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.claim_sources_id_seq OWNER TO postgres;

--
-- TOC entry 2556 (class 0 OID 0)
-- Dependencies: 233
-- Name: claim_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.claim_sources_id_seq OWNED BY public.claim_sources.id;


--
-- TOC entry 209 (class 1259 OID 16562)
-- Name: contacts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.contacts OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16560)
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contacts_id_seq OWNER TO postgres;

--
-- TOC entry 2557 (class 0 OID 0)
-- Dependencies: 208
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- TOC entry 216 (class 1259 OID 16651)
-- Name: dynamic_annotation_annotation_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_annotation_annotation_types (
    annotation_type character varying NOT NULL,
    label character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    singleton boolean DEFAULT true
);


ALTER TABLE public.dynamic_annotation_annotation_types OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16667)
-- Name: dynamic_annotation_field_instances; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.dynamic_annotation_field_instances OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16659)
-- Name: dynamic_annotation_field_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_annotation_field_types (
    field_type character varying NOT NULL,
    label character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.dynamic_annotation_field_types OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16680)
-- Name: dynamic_annotation_fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_annotation_fields (
    id integer NOT NULL,
    annotation_id integer NOT NULL,
    field_name character varying NOT NULL,
    annotation_type character varying NOT NULL,
    field_type character varying NOT NULL,
    value text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.dynamic_annotation_fields OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16678)
-- Name: dynamic_annotation_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dynamic_annotation_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dynamic_annotation_fields_id_seq OWNER TO postgres;

--
-- TOC entry 2558 (class 0 OID 0)
-- Dependencies: 219
-- Name: dynamic_annotation_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dynamic_annotation_fields_id_seq OWNED BY public.dynamic_annotation_fields.id;


--
-- TOC entry 205 (class 1259 OID 16521)
-- Name: medias; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.medias OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16519)
-- Name: medias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medias_id_seq OWNER TO postgres;

--
-- TOC entry 2559 (class 0 OID 0)
-- Dependencies: 204
-- Name: medias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medias_id_seq OWNED BY public.medias.id;


--
-- TOC entry 244 (class 1259 OID 16986)
-- Name: pghero_query_stats; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.pghero_query_stats OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16984)
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pghero_query_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pghero_query_stats_id_seq OWNER TO postgres;

--
-- TOC entry 2560 (class 0 OID 0)
-- Dependencies: 243
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pghero_query_stats_id_seq OWNED BY public.pghero_query_stats.id;


--
-- TOC entry 207 (class 1259 OID 16543)
-- Name: project_medias; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.project_medias OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16541)
-- Name: project_medias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_medias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_medias_id_seq OWNER TO postgres;

--
-- TOC entry 2561 (class 0 OID 0)
-- Dependencies: 206
-- Name: project_medias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_medias_id_seq OWNED BY public.project_medias.id;


--
-- TOC entry 201 (class 1259 OID 16489)
-- Name: project_sources; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.project_sources OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 16487)
-- Name: project_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_sources_id_seq OWNER TO postgres;

--
-- TOC entry 2562 (class 0 OID 0)
-- Dependencies: 200
-- Name: project_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_sources_id_seq OWNED BY public.project_sources.id;


--
-- TOC entry 191 (class 1259 OID 16428)
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.projects OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 16426)
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO postgres;

--
-- TOC entry 2563 (class 0 OID 0)
-- Dependencies: 190
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- TOC entry 238 (class 1259 OID 16919)
-- Name: relationships; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.relationships OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16917)
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relationships_id_seq OWNER TO postgres;

--
-- TOC entry 2564 (class 0 OID 0)
-- Dependencies: 237
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.relationships_id_seq OWNED BY public.relationships.id;


--
-- TOC entry 185 (class 1259 OID 16385)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 16477)
-- Name: sources; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.sources OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 16475)
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sources_id_seq OWNER TO postgres;

--
-- TOC entry 2565 (class 0 OID 0)
-- Dependencies: 198
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sources_id_seq OWNED BY public.sources.id;


--
-- TOC entry 246 (class 1259 OID 17001)
-- Name: tag_texts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.tag_texts OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16999)
-- Name: tag_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tag_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tag_texts_id_seq OWNER TO postgres;

--
-- TOC entry 2566 (class 0 OID 0)
-- Dependencies: 245
-- Name: tag_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tag_texts_id_seq OWNED BY public.tag_texts.id;


--
-- TOC entry 242 (class 1259 OID 16971)
-- Name: team_bot_installations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.team_bot_installations (
    id integer NOT NULL,
    team_id integer,
    team_bot_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    settings text
);


ALTER TABLE public.team_bot_installations OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16969)
-- Name: team_bot_installations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.team_bot_installations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.team_bot_installations_id_seq OWNER TO postgres;

--
-- TOC entry 2567 (class 0 OID 0)
-- Dependencies: 241
-- Name: team_bot_installations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.team_bot_installations_id_seq OWNED BY public.team_bot_installations.id;


--
-- TOC entry 240 (class 1259 OID 16956)
-- Name: team_bots; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.team_bots OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16954)
-- Name: team_bots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.team_bots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.team_bots_id_seq OWNER TO postgres;

--
-- TOC entry 2568 (class 0 OID 0)
-- Dependencies: 239
-- Name: team_bots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.team_bots_id_seq OWNED BY public.team_bots.id;


--
-- TOC entry 248 (class 1259 OID 17016)
-- Name: team_tasks; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.team_tasks OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 17014)
-- Name: team_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.team_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.team_tasks_id_seq OWNER TO postgres;

--
-- TOC entry 2569 (class 0 OID 0)
-- Dependencies: 247
-- Name: team_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.team_tasks_id_seq OWNED BY public.team_tasks.id;


--
-- TOC entry 197 (class 1259 OID 16467)
-- Name: team_users; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.team_users OWNER TO postgres;

--
-- TOC entry 196 (class 1259 OID 16465)
-- Name: team_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.team_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.team_users_id_seq OWNER TO postgres;

--
-- TOC entry 2570 (class 0 OID 0)
-- Dependencies: 196
-- Name: team_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.team_users_id_seq OWNED BY public.team_users.id;


--
-- TOC entry 195 (class 1259 OID 16454)
-- Name: teams; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.teams OWNER TO postgres;

--
-- TOC entry 194 (class 1259 OID 16452)
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teams_id_seq OWNER TO postgres;

--
-- TOC entry 2571 (class 0 OID 0)
-- Dependencies: 194
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- TOC entry 189 (class 1259 OID 16406)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
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
    last_accepted_terms_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 16404)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 2572 (class 0 OID 0)
-- Dependencies: 188
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 203 (class 1259 OID 16499)
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.versions OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16497)
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.versions_id_seq OWNER TO postgres;

--
-- TOC entry 2573 (class 0 OID 0)
-- Dependencies: 202
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- TOC entry 2279 (class 2604 OID 16796)
-- Name: account_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_sources ALTER COLUMN id SET DEFAULT nextval('public.account_sources_id_seq'::regclass);


--
-- TOC entry 2245 (class 2604 OID 16444)
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- TOC entry 2268 (class 2604 OID 16628)
-- Name: annotations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.annotations ALTER COLUMN id SET DEFAULT nextval('public.annotations_id_seq'::regclass);


--
-- TOC entry 2232 (class 2604 OID 16397)
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- TOC entry 2295 (class 2604 OID 17031)
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- TOC entry 2274 (class 2604 OID 16701)
-- Name: bot_alegres id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_alegres ALTER COLUMN id SET DEFAULT nextval('public.bot_alegres_id_seq'::regclass);


--
-- TOC entry 2266 (class 2604 OID 16591)
-- Name: bot_bots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_bots ALTER COLUMN id SET DEFAULT nextval('public.bot_bots_id_seq'::regclass);


--
-- TOC entry 2281 (class 2604 OID 16911)
-- Name: bot_bridge_readers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_bridge_readers ALTER COLUMN id SET DEFAULT nextval('public.bot_bridge_readers_id_seq'::regclass);


--
-- TOC entry 2277 (class 2604 OID 16747)
-- Name: bot_facebooks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_facebooks ALTER COLUMN id SET DEFAULT nextval('public.bot_facebooks_id_seq'::regclass);


--
-- TOC entry 2278 (class 2604 OID 16766)
-- Name: bot_slacks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_slacks ALTER COLUMN id SET DEFAULT nextval('public.bot_slacks_id_seq'::regclass);


--
-- TOC entry 2276 (class 2604 OID 16736)
-- Name: bot_twitters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_twitters ALTER COLUMN id SET DEFAULT nextval('public.bot_twitters_id_seq'::regclass);


--
-- TOC entry 2275 (class 2604 OID 16723)
-- Name: bot_vibers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_vibers ALTER COLUMN id SET DEFAULT nextval('public.bot_vibers_id_seq'::regclass);


--
-- TOC entry 2267 (class 2604 OID 16615)
-- Name: bounces id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bounces ALTER COLUMN id SET DEFAULT nextval('public.bounces_id_seq'::regclass);


--
-- TOC entry 2280 (class 2604 OID 16839)
-- Name: claim_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.claim_sources ALTER COLUMN id SET DEFAULT nextval('public.claim_sources_id_seq'::regclass);


--
-- TOC entry 2265 (class 2604 OID 16565)
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- TOC entry 2273 (class 2604 OID 16683)
-- Name: dynamic_annotation_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_annotation_fields ALTER COLUMN id SET DEFAULT nextval('public.dynamic_annotation_fields_id_seq'::regclass);


--
-- TOC entry 2258 (class 2604 OID 16524)
-- Name: medias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medias ALTER COLUMN id SET DEFAULT nextval('public.medias_id_seq'::regclass);


--
-- TOC entry 2289 (class 2604 OID 16989)
-- Name: pghero_query_stats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pghero_query_stats ALTER COLUMN id SET DEFAULT nextval('public.pghero_query_stats_id_seq'::regclass);


--
-- TOC entry 2259 (class 2604 OID 16546)
-- Name: project_medias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_medias ALTER COLUMN id SET DEFAULT nextval('public.project_medias_id_seq'::regclass);


--
-- TOC entry 2255 (class 2604 OID 16492)
-- Name: project_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_sources ALTER COLUMN id SET DEFAULT nextval('public.project_sources_id_seq'::regclass);


--
-- TOC entry 2242 (class 2604 OID 16431)
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- TOC entry 2282 (class 2604 OID 16922)
-- Name: relationships id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationships ALTER COLUMN id SET DEFAULT nextval('public.relationships_id_seq'::regclass);


--
-- TOC entry 2252 (class 2604 OID 16480)
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- TOC entry 2290 (class 2604 OID 17004)
-- Name: tag_texts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tag_texts ALTER COLUMN id SET DEFAULT nextval('public.tag_texts_id_seq'::regclass);


--
-- TOC entry 2288 (class 2604 OID 16974)
-- Name: team_bot_installations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_bot_installations ALTER COLUMN id SET DEFAULT nextval('public.team_bot_installations_id_seq'::regclass);


--
-- TOC entry 2283 (class 2604 OID 16959)
-- Name: team_bots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_bots ALTER COLUMN id SET DEFAULT nextval('public.team_bots_id_seq'::regclass);


--
-- TOC entry 2293 (class 2604 OID 17019)
-- Name: team_tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_tasks ALTER COLUMN id SET DEFAULT nextval('public.team_tasks_id_seq'::regclass);


--
-- TOC entry 2250 (class 2604 OID 16470)
-- Name: team_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_users ALTER COLUMN id SET DEFAULT nextval('public.team_users_id_seq'::regclass);


--
-- TOC entry 2246 (class 2604 OID 16457)
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- TOC entry 2234 (class 2604 OID 16409)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 2257 (class 2604 OID 16502)
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- TOC entry 2380 (class 2606 OID 16798)
-- Name: account_sources account_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_sources
    ADD CONSTRAINT account_sources_pkey PRIMARY KEY (id);


--
-- TOC entry 2314 (class 2606 OID 16449)
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 2354 (class 2606 OID 16633)
-- Name: annotations annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- TOC entry 2298 (class 2606 OID 16403)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- TOC entry 2410 (class 2606 OID 17033)
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 2370 (class 2606 OID 16706)
-- Name: bot_alegres bot_alegres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_alegres
    ADD CONSTRAINT bot_alegres_pkey PRIMARY KEY (id);


--
-- TOC entry 2349 (class 2606 OID 16596)
-- Name: bot_bots bot_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_bots
    ADD CONSTRAINT bot_bots_pkey PRIMARY KEY (id);


--
-- TOC entry 2387 (class 2606 OID 16916)
-- Name: bot_bridge_readers bot_bridge_readers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_bridge_readers
    ADD CONSTRAINT bot_bridge_readers_pkey PRIMARY KEY (id);


--
-- TOC entry 2376 (class 2606 OID 16752)
-- Name: bot_facebooks bot_facebooks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_facebooks
    ADD CONSTRAINT bot_facebooks_pkey PRIMARY KEY (id);


--
-- TOC entry 2378 (class 2606 OID 16771)
-- Name: bot_slacks bot_slacks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_slacks
    ADD CONSTRAINT bot_slacks_pkey PRIMARY KEY (id);


--
-- TOC entry 2374 (class 2606 OID 16741)
-- Name: bot_twitters bot_twitters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_twitters
    ADD CONSTRAINT bot_twitters_pkey PRIMARY KEY (id);


--
-- TOC entry 2372 (class 2606 OID 16728)
-- Name: bot_vibers bot_vibers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bot_vibers
    ADD CONSTRAINT bot_vibers_pkey PRIMARY KEY (id);


--
-- TOC entry 2351 (class 2606 OID 16620)
-- Name: bounces bounces_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bounces
    ADD CONSTRAINT bounces_pkey PRIMARY KEY (id);


--
-- TOC entry 2384 (class 2606 OID 16841)
-- Name: claim_sources claim_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.claim_sources
    ADD CONSTRAINT claim_sources_pkey PRIMARY KEY (id);


--
-- TOC entry 2347 (class 2606 OID 16570)
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- TOC entry 2359 (class 2606 OID 16658)
-- Name: dynamic_annotation_annotation_types dynamic_annotation_annotation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_annotation_annotation_types
    ADD CONSTRAINT dynamic_annotation_annotation_types_pkey PRIMARY KEY (annotation_type);


--
-- TOC entry 2363 (class 2606 OID 16675)
-- Name: dynamic_annotation_field_instances dynamic_annotation_field_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_annotation_field_instances
    ADD CONSTRAINT dynamic_annotation_field_instances_pkey PRIMARY KEY (name);


--
-- TOC entry 2361 (class 2606 OID 16666)
-- Name: dynamic_annotation_field_types dynamic_annotation_field_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_annotation_field_types
    ADD CONSTRAINT dynamic_annotation_field_types_pkey PRIMARY KEY (field_type);


--
-- TOC entry 2365 (class 2606 OID 16688)
-- Name: dynamic_annotation_fields dynamic_annotation_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_annotation_fields
    ADD CONSTRAINT dynamic_annotation_fields_pkey PRIMARY KEY (id);


--
-- TOC entry 2339 (class 2606 OID 16529)
-- Name: medias medias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medias
    ADD CONSTRAINT medias_pkey PRIMARY KEY (id);


--
-- TOC entry 2403 (class 2606 OID 16994)
-- Name: pghero_query_stats pghero_query_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pghero_query_stats
    ADD CONSTRAINT pghero_query_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 2345 (class 2606 OID 16548)
-- Name: project_medias project_medias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_medias
    ADD CONSTRAINT project_medias_pkey PRIMARY KEY (id);


--
-- TOC entry 2332 (class 2606 OID 16494)
-- Name: project_sources project_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_sources
    ADD CONSTRAINT project_sources_pkey PRIMARY KEY (id);


--
-- TOC entry 2312 (class 2606 OID 16436)
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- TOC entry 2390 (class 2606 OID 16927)
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- TOC entry 2329 (class 2606 OID 16485)
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- TOC entry 2406 (class 2606 OID 17011)
-- Name: tag_texts tag_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tag_texts
    ADD CONSTRAINT tag_texts_pkey PRIMARY KEY (id);


--
-- TOC entry 2400 (class 2606 OID 16976)
-- Name: team_bot_installations team_bot_installations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_bot_installations
    ADD CONSTRAINT team_bot_installations_pkey PRIMARY KEY (id);


--
-- TOC entry 2396 (class 2606 OID 16968)
-- Name: team_bots team_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_bots
    ADD CONSTRAINT team_bots_pkey PRIMARY KEY (id);


--
-- TOC entry 2408 (class 2606 OID 17025)
-- Name: team_tasks team_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_tasks
    ADD CONSTRAINT team_tasks_pkey PRIMARY KEY (id);


--
-- TOC entry 2327 (class 2606 OID 16472)
-- Name: team_users team_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_users
    ADD CONSTRAINT team_users_pkey PRIMARY KEY (id);


--
-- TOC entry 2321 (class 2606 OID 16464)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- TOC entry 2307 (class 2606 OID 16422)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 2335 (class 2606 OID 16507)
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- TOC entry 2381 (class 1259 OID 16890)
-- Name: index_account_sources_on_account_id_and_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_account_sources_on_account_id_and_source_id ON public.account_sources USING btree (account_id, source_id);


--
-- TOC entry 2382 (class 1259 OID 16800)
-- Name: index_account_sources_on_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_account_sources_on_source_id ON public.account_sources USING btree (source_id);


--
-- TOC entry 2315 (class 1259 OID 17056)
-- Name: index_accounts_on_uid_and_provider_and_token_and_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_accounts_on_uid_and_provider_and_token_and_email ON public.accounts USING btree (uid, provider, token, email);


--
-- TOC entry 2316 (class 1259 OID 16572)
-- Name: index_accounts_on_url; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_accounts_on_url ON public.accounts USING btree (url);


--
-- TOC entry 2355 (class 1259 OID 17078)
-- Name: index_annotation_type_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_annotation_type_order ON public.annotations USING btree (annotation_type);


--
-- TOC entry 2356 (class 1259 OID 16635)
-- Name: index_annotations_on_annotated_type_and_annotated_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_annotations_on_annotated_type_and_annotated_id ON public.annotations USING btree (annotated_type, annotated_id);


--
-- TOC entry 2357 (class 1259 OID 16634)
-- Name: index_annotations_on_annotation_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_annotations_on_annotation_type ON public.annotations USING btree (annotation_type);


--
-- TOC entry 2411 (class 1259 OID 17034)
-- Name: index_assignments_on_assigned_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_assigned_id ON public.assignments USING btree (assigned_id);


--
-- TOC entry 2412 (class 1259 OID 17041)
-- Name: index_assignments_on_assigned_id_and_assigned_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_assigned_id_and_assigned_type ON public.assignments USING btree (assigned_id, assigned_type);


--
-- TOC entry 2413 (class 1259 OID 17042)
-- Name: index_assignments_on_assigned_id_and_assigned_type_and_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_assignments_on_assigned_id_and_assigned_type_and_user_id ON public.assignments USING btree (assigned_id, assigned_type, user_id);


--
-- TOC entry 2414 (class 1259 OID 17040)
-- Name: index_assignments_on_assigned_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_assigned_type ON public.assignments USING btree (assigned_type);


--
-- TOC entry 2415 (class 1259 OID 17035)
-- Name: index_assignments_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_user_id ON public.assignments USING btree (user_id);


--
-- TOC entry 2352 (class 1259 OID 16621)
-- Name: index_bounces_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_bounces_on_email ON public.bounces USING btree (email);


--
-- TOC entry 2385 (class 1259 OID 16891)
-- Name: index_claim_sources_on_media_id_and_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_claim_sources_on_media_id_and_source_id ON public.claim_sources USING btree (media_id, source_id);


--
-- TOC entry 2366 (class 1259 OID 16689)
-- Name: index_dynamic_annotation_fields_on_annotation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_dynamic_annotation_fields_on_annotation_id ON public.dynamic_annotation_fields USING btree (annotation_id);


--
-- TOC entry 2367 (class 1259 OID 16692)
-- Name: index_dynamic_annotation_fields_on_field_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_dynamic_annotation_fields_on_field_type ON public.dynamic_annotation_fields USING btree (field_type);


--
-- TOC entry 2336 (class 1259 OID 16607)
-- Name: index_medias_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_medias_on_id ON public.medias USING btree (id);


--
-- TOC entry 2337 (class 1259 OID 16573)
-- Name: index_medias_on_url; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_medias_on_url ON public.medias USING btree (url);


--
-- TOC entry 2401 (class 1259 OID 16995)
-- Name: index_pghero_query_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_pghero_query_stats_on_database_and_captured_at ON public.pghero_query_stats USING btree (database, captured_at);


--
-- TOC entry 2340 (class 1259 OID 16606)
-- Name: index_project_medias_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_project_medias_on_id ON public.project_medias USING btree (id);


--
-- TOC entry 2341 (class 1259 OID 26142)
-- Name: index_project_medias_on_inactive; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_project_medias_on_inactive ON public.project_medias USING btree (inactive);


--
-- TOC entry 2342 (class 1259 OID 16550)
-- Name: index_project_medias_on_media_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_project_medias_on_media_id ON public.project_medias USING btree (media_id);


--
-- TOC entry 2343 (class 1259 OID 16892)
-- Name: index_project_medias_on_project_id_and_media_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_project_medias_on_project_id_and_media_id ON public.project_medias USING btree (project_id, media_id);


--
-- TOC entry 2330 (class 1259 OID 16889)
-- Name: index_project_sources_on_project_id_and_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_project_sources_on_project_id_and_source_id ON public.project_sources USING btree (project_id, source_id);


--
-- TOC entry 2308 (class 1259 OID 16608)
-- Name: index_projects_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_projects_on_id ON public.projects USING btree (id);


--
-- TOC entry 2309 (class 1259 OID 16438)
-- Name: index_projects_on_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_projects_on_team_id ON public.projects USING btree (team_id);


--
-- TOC entry 2310 (class 1259 OID 16730)
-- Name: index_projects_on_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_projects_on_token ON public.projects USING btree (token);


--
-- TOC entry 2404 (class 1259 OID 17012)
-- Name: index_tag_texts_on_text_and_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_tag_texts_on_text_and_team_id ON public.tag_texts USING btree (text, team_id);


--
-- TOC entry 2397 (class 1259 OID 16982)
-- Name: index_team_bot_installations_on_team_bot_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_bot_installations_on_team_bot_id ON public.team_bot_installations USING btree (team_bot_id);


--
-- TOC entry 2398 (class 1259 OID 16983)
-- Name: index_team_bot_installations_on_team_id_and_team_bot_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_team_bot_installations_on_team_id_and_team_bot_id ON public.team_bot_installations USING btree (team_id, team_bot_id);


--
-- TOC entry 2391 (class 1259 OID 16979)
-- Name: index_team_bots_on_approved; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_bots_on_approved ON public.team_bots USING btree (approved);


--
-- TOC entry 2392 (class 1259 OID 16977)
-- Name: index_team_bots_on_bot_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_bots_on_bot_user_id ON public.team_bots USING btree (bot_user_id);


--
-- TOC entry 2393 (class 1259 OID 16980)
-- Name: index_team_bots_on_identifier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_team_bots_on_identifier ON public.team_bots USING btree (identifier);


--
-- TOC entry 2394 (class 1259 OID 16978)
-- Name: index_team_bots_on_team_author_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_bots_on_team_author_id ON public.team_bots USING btree (team_author_id);


--
-- TOC entry 2323 (class 1259 OID 16605)
-- Name: index_team_users_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_users_on_id ON public.team_users USING btree (id);


--
-- TOC entry 2324 (class 1259 OID 16585)
-- Name: index_team_users_on_team_id_and_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_team_users_on_team_id_and_user_id ON public.team_users USING btree (team_id, user_id);


--
-- TOC entry 2325 (class 1259 OID 16717)
-- Name: index_team_users_on_user_id_and_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_team_users_on_user_id_and_team_id ON public.team_users USING btree (user_id, team_id);


--
-- TOC entry 2317 (class 1259 OID 16609)
-- Name: index_teams_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_teams_on_id ON public.teams USING btree (id);


--
-- TOC entry 2318 (class 1259 OID 17069)
-- Name: index_teams_on_inactive; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_teams_on_inactive ON public.teams USING btree (inactive);


--
-- TOC entry 2319 (class 1259 OID 16574)
-- Name: index_teams_on_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_teams_on_slug ON public.teams USING btree (slug);


--
-- TOC entry 2299 (class 1259 OID 16622)
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- TOC entry 2300 (class 1259 OID 17057)
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_users_on_email ON public.users USING btree (email);


--
-- TOC entry 2301 (class 1259 OID 16604)
-- Name: index_users_on_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_users_on_id ON public.users USING btree (id);


--
-- TOC entry 2302 (class 1259 OID 17013)
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- TOC entry 2303 (class 1259 OID 16423)
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- TOC entry 2304 (class 1259 OID 17077)
-- Name: index_users_on_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_users_on_source_id ON public.users USING btree (source_id);


--
-- TOC entry 2305 (class 1259 OID 16425)
-- Name: index_users_on_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_token ON public.users USING btree (token);


--
-- TOC entry 2333 (class 1259 OID 16810)
-- Name: index_versions_on_associated_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_associated_id ON public.versions USING btree (associated_id);


--
-- TOC entry 2388 (class 1259 OID 16931)
-- Name: relationship_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX relationship_index ON public.relationships USING btree (source_id, target_id, relationship_type);


--
-- TOC entry 2368 (class 1259 OID 16729)
-- Name: translation_request_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX translation_request_id ON public.dynamic_annotation_fields USING btree (value) WHERE ((field_name)::text = 'translation_request_id'::text);


--
-- TOC entry 2296 (class 1259 OID 16391)
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- TOC entry 2322 (class 1259 OID 17054)
-- Name: unique_team_slugs; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_team_slugs ON public.teams USING btree (slug);


--
-- TOC entry 2417 (class 2606 OID 16555)
-- Name: accounts fk_rails_16c8fecc67; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_16c8fecc67 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- TOC entry 2420 (class 2606 OID 16598)
-- Name: project_medias fk_rails_747821fe70; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_medias
    ADD CONSTRAINT fk_rails_747821fe70 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 2416 (class 2606 OID 16780)
-- Name: users fk_rails_869bf2c95b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_869bf2c95b FOREIGN KEY (source_id) REFERENCES public.sources(id);


--
-- TOC entry 2418 (class 2606 OID 16786)
-- Name: sources fk_rails_8907b64d78; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT fk_rails_8907b64d78 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- TOC entry 2419 (class 2606 OID 16774)
-- Name: project_sources fk_rails_a45f01cbd6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_sources
    ADD CONSTRAINT fk_rails_a45f01cbd6 FOREIGN KEY (user_id) REFERENCES public.users(id);


-- Completed on 2019-04-16 12:28:00 PDT

--
-- PostgreSQL database dump complete
--

