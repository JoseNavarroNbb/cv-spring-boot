/* =============================================================================
   BASE DE DATOS: CV DINÁMICO
   Motor        : PostgreSQL 15+ (Supabase)
   Backend      : Spring Boot 3.x / Java 17 (JPA + Hibernate)
   Convenciones : snake_case, tablas en singular, PK = id,
                  FK = <tabla>_id, constraints con prefijo pk_/fk_/uq_/ck_/idx_
   Tipos        : smallint (catálogos) | integer (entidades) | bigint (eventos)
   Auditoría    : creado_en / actualizado_en (timestamptz, en UTC)
   ============================================================================= */

begin;

-- =============================================================================
-- 0. FUNCIONES UTILITARIAS
-- =============================================================================

-- Actualiza automáticamente la columna actualizado_en en cada UPDATE
create or replace function fn_actualizar_fecha_modificacion()
returns trigger
language plpgsql
as $$
begin
    new.actualizado_en := now();
    return new;
end;
$$;

comment on function fn_actualizar_fecha_modificacion()
    is 'Trigger genérico: asigna now() a actualizado_en antes de cada UPDATE.';

-- Calcula la edad en años cumplidos a partir de la fecha de nacimiento
create or replace function fn_calcular_edad(p_fecha_nacimiento date)
returns integer
language sql
stable
as $$
    select case
        when p_fecha_nacimiento is null then null
        else date_part('year', age(current_date, p_fecha_nacimiento))::integer
    end;
$$;

comment on function fn_calcular_edad(date)
    is 'Devuelve la edad en años cumplidos. La edad no se guarda porque cambia cada año.';


-- =============================================================================
-- 1. CATÁLOGOS (tablas pequeñas, rara vez cambian)
-- =============================================================================

-- 1.1 rol -----------------------------------------------------------------
create table rol (
    id            smallint     generated always as identity,
    codigo        varchar(30)  not null,
    nombre        varchar(60)  not null,
    descripcion   varchar(200),
    constraint pk_rol        primary key (id),
    constraint uq_rol_codigo unique (codigo)
);
comment on table  rol             is 'Catálogo de roles de seguridad del sistema.';
comment on column rol.id          is 'Identificador único del rol.';
comment on column rol.codigo      is 'Código técnico del rol (ej. ADMIN). Se usa en Spring Security.';
comment on column rol.nombre      is 'Nombre legible del rol.';
comment on column rol.descripcion is 'Descripción de los permisos que otorga el rol.';

-- 1.2 pais ----------------------------------------------------------------
create table pais (
    id           smallint     generated always as identity,
    codigo_iso   char(2)      not null,
    nombre       varchar(80)  not null,
    constraint pk_pais            primary key (id),
    constraint uq_pais_codigo_iso unique (codigo_iso)
);
comment on table  pais            is 'Catálogo de países (ISO 3166-1 alfa-2).';
comment on column pais.id         is 'Identificador único del país.';
comment on column pais.codigo_iso is 'Código ISO de dos letras (ej. MX).';
comment on column pais.nombre     is 'Nombre del país en español.';

-- 1.3 idioma --------------------------------------------------------------
create table idioma (
    id        smallint     generated always as identity,
    codigo    varchar(10)  not null,
    nombre    varchar(40)  not null,
    constraint pk_idioma        primary key (id),
    constraint uq_idioma_codigo unique (codigo)
);
comment on table  idioma        is 'Catálogo de idiomas (para hablados y para el idioma del CV).';
comment on column idioma.id     is 'Identificador único del idioma.';
comment on column idioma.codigo is 'Código ISO 639-1 (ej. es, en).';
comment on column idioma.nombre is 'Nombre del idioma en español.';

-- 1.4 nivel_idioma --------------------------------------------------------
create table nivel_idioma (
    id        smallint     generated always as identity,
    codigo    varchar(10)  not null,
    nombre    varchar(40)  not null,
    orden     smallint     not null default 0,
    constraint pk_nivel_idioma        primary key (id),
    constraint uq_nivel_idioma_codigo unique (codigo)
);
comment on table  nivel_idioma        is 'Catálogo de niveles de dominio de idioma (MCER + nativo).';
comment on column nivel_idioma.id     is 'Identificador único del nivel.';
comment on column nivel_idioma.codigo is 'Código del nivel (A1, A2, B1, B2, C1, C2, NATIVO).';
comment on column nivel_idioma.nombre is 'Nombre legible del nivel.';
comment on column nivel_idioma.orden  is 'Orden ascendente de dominio, útil para ordenar y filtrar.';

-- 1.5 nivel_academico -----------------------------------------------------
create table nivel_academico (
    id        smallint     generated always as identity,
    codigo    varchar(30)  not null,
    nombre    varchar(60)  not null,
    orden     smallint     not null default 0,
    constraint pk_nivel_academico        primary key (id),
    constraint uq_nivel_academico_codigo unique (codigo)
);
comment on table  nivel_academico        is 'Catálogo de niveles académicos (licenciatura, maestría, diplomado...).';
comment on column nivel_academico.id     is 'Identificador único del nivel académico.';
comment on column nivel_academico.codigo is 'Código técnico del nivel (ej. LICENCIATURA).';
comment on column nivel_academico.nombre is 'Nombre legible del nivel académico.';
comment on column nivel_academico.orden  is 'Orden jerárquico ascendente.';

-- 1.6 tipo_contacto -------------------------------------------------------
create table tipo_contacto (
    id          smallint     generated always as identity,
    codigo      varchar(30)  not null,
    nombre      varchar(60)  not null,
    icono       varchar(60),
    constraint pk_tipo_contacto        primary key (id),
    constraint uq_tipo_contacto_codigo unique (codigo)
);
comment on table  tipo_contacto        is 'Catálogo de medios de contacto y redes (correo, teléfono, LinkedIn...).';
comment on column tipo_contacto.id     is 'Identificador único del tipo de contacto.';
comment on column tipo_contacto.codigo is 'Código técnico (ej. CORREO, TELEFONO, LINKEDIN).';
comment on column tipo_contacto.nombre is 'Nombre legible del medio de contacto.';
comment on column tipo_contacto.icono  is 'Nombre del ícono que usará el frontend (ej. mdi-email).';

-- 1.7 tipo_seccion --------------------------------------------------------
create table tipo_seccion (
    id          smallint     generated always as identity,
    codigo      varchar(30)  not null,
    nombre      varchar(60)  not null,
    constraint pk_tipo_seccion        primary key (id),
    constraint uq_tipo_seccion_codigo unique (codigo)
);
comment on table  tipo_seccion        is 'Catálogo de secciones que puede mostrar un CV.';
comment on column tipo_seccion.id     is 'Identificador único del tipo de sección.';
comment on column tipo_seccion.codigo is 'Código técnico (ej. EXPERIENCIA, PROYECTOS).';
comment on column tipo_seccion.nombre is 'Nombre por defecto de la sección.';

-- 1.8 categoria_habilidad -------------------------------------------------
create table categoria_habilidad (
    id        smallint     generated always as identity,
    nombre    varchar(60)  not null,
    orden     smallint     not null default 0,
    constraint pk_categoria_habilidad        primary key (id),
    constraint uq_categoria_habilidad_nombre unique (nombre)
);
comment on table  categoria_habilidad        is 'Categorías para agrupar habilidades (Lenguajes, Frameworks, Bases de datos...).';
comment on column categoria_habilidad.id     is 'Identificador único de la categoría.';
comment on column categoria_habilidad.nombre is 'Nombre de la categoría.';
comment on column categoria_habilidad.orden  is 'Orden de aparición en el CV.';

-- 1.9 tipo_evento (analítica) ---------------------------------------------
create table tipo_evento (
    id          smallint     generated always as identity,
    codigo      varchar(30)  not null,
    nombre      varchar(80)  not null,
    constraint pk_tipo_evento        primary key (id),
    constraint uq_tipo_evento_codigo unique (codigo)
);
comment on table  tipo_evento        is 'Catálogo de eventos de analítica que se registran sobre el CV.';
comment on column tipo_evento.id     is 'Identificador único del tipo de evento.';
comment on column tipo_evento.codigo is 'Código técnico (ej. VISTA_CV, CLIC_ENLACE, DESCARGA_PDF).';
comment on column tipo_evento.nombre is 'Descripción legible del evento.';


-- =============================================================================
-- 2. SEGURIDAD Y PERSONA
-- =============================================================================

-- 2.1 usuario -------------------------------------------------------------
create table usuario (
    id                integer      generated always as identity,
    correo            varchar(150) not null,
    contrasena_hash   varchar(255) not null,
    rol_id            smallint     not null,
    activo            boolean      not null default true,
    ultimo_acceso_en  timestamptz,
    creado_en         timestamptz  not null default now(),
    actualizado_en    timestamptz  not null default now(),
    constraint pk_usuario     primary key (id),
    constraint fk_usuario_rol foreign key (rol_id) references rol (id),
    constraint ck_usuario_correo check (position('@' in correo) > 1)
);
create unique index uq_usuario_correo on usuario (lower(correo));
create index idx_usuario_rol_id on usuario (rol_id);

comment on table  usuario                  is 'Cuentas de acceso al administrador del CV.';
comment on column usuario.id               is 'Identificador único del usuario.';
comment on column usuario.correo           is 'Correo de inicio de sesión. Único sin distinguir mayúsculas.';
comment on column usuario.contrasena_hash  is 'Contraseña cifrada con BCrypt. Nunca se guarda en texto plano.';
comment on column usuario.rol_id           is 'Rol de seguridad asignado al usuario.';
comment on column usuario.activo           is 'Indica si la cuenta puede iniciar sesión.';
comment on column usuario.ultimo_acceso_en is 'Fecha y hora del último inicio de sesión exitoso.';
comment on column usuario.creado_en        is 'Fecha de creación del registro.';
comment on column usuario.actualizado_en   is 'Fecha de la última modificación del registro.';

-- 2.2 persona -------------------------------------------------------------
create table persona (
    id                    integer      generated always as identity,
    usuario_id            integer      not null,
    nombre                varchar(80)  not null,
    apellido_paterno      varchar(60)  not null,
    apellido_materno      varchar(60),
    nombre_completo       varchar(200) generated always as (
                              nombre || ' ' || apellido_paterno || coalesce(' ' || apellido_materno, '')
                          ) stored,
    fecha_nacimiento      date,
    titulo_profesional    varchar(150),
    foto_url              varchar(500),
    ciudad                varchar(80),
    estado                varchar(80),
    pais_id               smallint,
    creado_en             timestamptz  not null default now(),
    actualizado_en        timestamptz  not null default now(),
    constraint pk_persona         primary key (id),
    constraint uq_persona_usuario unique (usuario_id),
    constraint fk_persona_usuario foreign key (usuario_id) references usuario (id) on delete cascade,
    constraint fk_persona_pais    foreign key (pais_id)    references pais (id)
);
create index idx_persona_pais_id on persona (pais_id);

comment on table  persona                    is 'Datos personales del dueño del CV. Relación 1 a 1 con usuario.';
comment on column persona.id                 is 'Identificador único de la persona.';
comment on column persona.usuario_id         is 'Usuario al que pertenece la persona (relación 1 a 1).';
comment on column persona.nombre             is 'Nombre(s) de pila.';
comment on column persona.apellido_paterno   is 'Apellido paterno.';
comment on column persona.apellido_materno   is 'Apellido materno (opcional).';
comment on column persona.nombre_completo    is 'Nombre completo calculado automáticamente. Solo lectura.';
comment on column persona.fecha_nacimiento   is 'Fecha de nacimiento. La edad se calcula con fn_calcular_edad o vw_persona.';
comment on column persona.titulo_profesional is 'Título profesional (ej. Licenciado en Ciencias de la Computación).';
comment on column persona.foto_url           is 'URL de la fotografía de perfil.';
comment on column persona.ciudad             is 'Ciudad de residencia.';
comment on column persona.estado             is 'Estado o región de residencia.';
comment on column persona.pais_id            is 'País de residencia.';
comment on column persona.creado_en          is 'Fecha de creación del registro.';
comment on column persona.actualizado_en     is 'Fecha de la última modificación del registro.';

-- 2.3 persona_contacto ----------------------------------------------------
create table persona_contacto (
    id                integer       generated always as identity,
    persona_id        integer       not null,
    tipo_contacto_id  smallint      not null,
    valor             varchar(300)  not null,
    etiqueta          varchar(80),
    es_principal      boolean       not null default false,
    visible           boolean       not null default true,
    orden             smallint      not null default 0,
    creado_en         timestamptz   not null default now(),
    actualizado_en    timestamptz   not null default now(),
    constraint pk_persona_contacto         primary key (id),
    constraint fk_persona_contacto_persona foreign key (persona_id)       references persona (id)       on delete cascade,
    constraint fk_persona_contacto_tipo    foreign key (tipo_contacto_id) references tipo_contacto (id)
);
create index idx_persona_contacto_persona_id on persona_contacto (persona_id);
create index idx_persona_contacto_tipo_id    on persona_contacto (tipo_contacto_id);

comment on table  persona_contacto                  is 'Medios de contacto y enlaces de la persona (correo, teléfono, LinkedIn, portafolio).';
comment on column persona_contacto.id               is 'Identificador único del contacto.';
comment on column persona_contacto.persona_id       is 'Persona dueña del contacto.';
comment on column persona_contacto.tipo_contacto_id is 'Tipo de medio de contacto.';
comment on column persona_contacto.valor            is 'Valor del contacto: correo, teléfono o URL.';
comment on column persona_contacto.etiqueta         is 'Texto a mostrar en el CV (ej. Portafolio). Si es nulo se usa el nombre del tipo.';
comment on column persona_contacto.es_principal     is 'Indica si es el contacto principal de su tipo.';
comment on column persona_contacto.visible          is 'Si es falso no se muestra en el CV público.';
comment on column persona_contacto.orden            is 'Orden de aparición.';
comment on column persona_contacto.creado_en        is 'Fecha de creación del registro.';
comment on column persona_contacto.actualizado_en   is 'Fecha de la última modificación del registro.';

-- 2.4 persona_idioma ------------------------------------------------------
create table persona_idioma (
    id               integer       generated always as identity,
    persona_id       integer       not null,
    idioma_id        smallint      not null,
    nivel_idioma_id  smallint      not null,
    observacion      varchar(100),
    visible          boolean       not null default true,
    orden            smallint      not null default 0,
    creado_en        timestamptz   not null default now(),
    actualizado_en   timestamptz   not null default now(),
    constraint pk_persona_idioma         primary key (id),
    constraint uq_persona_idioma         unique (persona_id, idioma_id),
    constraint fk_persona_idioma_persona foreign key (persona_id)      references persona (id) on delete cascade,
    constraint fk_persona_idioma_idioma  foreign key (idioma_id)       references idioma (id),
    constraint fk_persona_idioma_nivel   foreign key (nivel_idioma_id) references nivel_idioma (id)
);
create index idx_persona_idioma_idioma_id on persona_idioma (idioma_id);
create index idx_persona_idioma_nivel_id  on persona_idioma (nivel_idioma_id);

comment on table  persona_idioma                  is 'Idiomas que habla la persona y su nivel de dominio.';
comment on column persona_idioma.id               is 'Identificador único del registro.';
comment on column persona_idioma.persona_id       is 'Persona que habla el idioma.';
comment on column persona_idioma.idioma_id        is 'Idioma hablado.';
comment on column persona_idioma.nivel_idioma_id  is 'Nivel de dominio del idioma.';
comment on column persona_idioma.observacion      is 'Aclaración opcional (ej. Técnico).';
comment on column persona_idioma.visible          is 'Si es falso no se muestra en el CV público.';
comment on column persona_idioma.orden            is 'Orden de aparición.';
comment on column persona_idioma.creado_en        is 'Fecha de creación del registro.';
comment on column persona_idioma.actualizado_en   is 'Fecha de la última modificación del registro.';


-- =============================================================================
-- 3. CV (versión publicable) Y SUS SECCIONES
-- =============================================================================

-- 3.1 cv ------------------------------------------------------------------
create table cv (
    id                   integer       generated always as identity,
    persona_id           integer       not null,
    slug                 varchar(80)   not null,
    titulo               varchar(150)  not null,
    titular              varchar(200),
    resumen_profesional  text,
    idioma_id            smallint      not null,
    url_pdf              varchar(500),
    es_principal         boolean       not null default false,
    es_publico           boolean       not null default true,
    publicado_en         timestamptz,
    creado_en            timestamptz   not null default now(),
    actualizado_en       timestamptz   not null default now(),
    constraint pk_cv         primary key (id),
    constraint uq_cv_slug    unique (slug),
    constraint fk_cv_persona foreign key (persona_id) references persona (id) on delete cascade,
    constraint fk_cv_idioma  foreign key (idioma_id)  references idioma (id),
    constraint ck_cv_slug    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);
create index idx_cv_persona_id on cv (persona_id);
create index idx_cv_idioma_id  on cv (idioma_id);
-- Solo un CV principal por persona
create unique index uq_cv_principal_por_persona on cv (persona_id) where es_principal;

comment on table  cv                     is 'Versión publicable del CV. Una persona puede tener varias (idioma, enfoque).';
comment on column cv.id                  is 'Identificador único del CV.';
comment on column cv.persona_id          is 'Persona dueña del CV.';
comment on column cv.slug                is 'Identificador para la URL pública (ej. jose-carlos-fullstack).';
comment on column cv.titulo              is 'Título interno del CV, visible en el administrador.';
comment on column cv.titular             is 'Encabezado profesional (ej. Desarrollador Full Stack | Laravel + Vue.js).';
comment on column cv.resumen_profesional is 'Texto del perfil profesional.';
comment on column cv.idioma_id           is 'Idioma en el que está redactado el CV.';
comment on column cv.url_pdf             is 'URL del PDF descargable del CV.';
comment on column cv.es_principal        is 'Marca el CV por defecto de la persona. Solo uno puede ser principal.';
comment on column cv.es_publico          is 'Si es falso, el CV no se expone en la consulta pública.';
comment on column cv.publicado_en        is 'Fecha de la última publicación.';
comment on column cv.creado_en           is 'Fecha de creación del registro.';
comment on column cv.actualizado_en      is 'Fecha de la última modificación del registro.';

-- 3.2 cv_seccion ----------------------------------------------------------
create table cv_seccion (
    id                    integer       generated always as identity,
    cv_id                 integer       not null,
    tipo_seccion_id       smallint      not null,
    titulo_personalizado  varchar(100),
    orden                 smallint      not null default 0,
    visible               boolean       not null default true,
    creado_en             timestamptz   not null default now(),
    actualizado_en        timestamptz   not null default now(),
    constraint pk_cv_seccion         primary key (id),
    constraint uq_cv_seccion         unique (cv_id, tipo_seccion_id),
    constraint fk_cv_seccion_cv      foreign key (cv_id)           references cv (id) on delete cascade,
    constraint fk_cv_seccion_tipo    foreign key (tipo_seccion_id) references tipo_seccion (id)
);
create index idx_cv_seccion_tipo_id on cv_seccion (tipo_seccion_id);

comment on table  cv_seccion                      is 'Secciones activas de un CV y su orden de aparición.';
comment on column cv_seccion.id                   is 'Identificador único de la sección del CV.';
comment on column cv_seccion.cv_id                is 'CV al que pertenece la sección.';
comment on column cv_seccion.tipo_seccion_id      is 'Tipo de sección (experiencia, proyectos, etc.).';
comment on column cv_seccion.titulo_personalizado is 'Título alterno para la sección. Si es nulo se usa el del catálogo.';
comment on column cv_seccion.orden                is 'Posición de la sección dentro del CV.';
comment on column cv_seccion.visible              is 'Si es falso la sección se oculta.';
comment on column cv_seccion.creado_en            is 'Fecha de creación del registro.';
comment on column cv_seccion.actualizado_en       is 'Fecha de la última modificación del registro.';


-- =============================================================================
-- 4. HABILIDADES
-- =============================================================================

-- 4.1 habilidad -----------------------------------------------------------
create table habilidad (
    id            integer       generated always as identity,
    categoria_id  smallint      not null,
    nombre        varchar(80)   not null,
    icono         varchar(60),
    sitio_web     varchar(300),
    activo        boolean       not null default true,
    creado_en     timestamptz   not null default now(),
    actualizado_en timestamptz  not null default now(),
    constraint pk_habilidad           primary key (id),
    constraint uq_habilidad_nombre    unique (categoria_id, nombre),
    constraint fk_habilidad_categoria foreign key (categoria_id) references categoria_habilidad (id)
);

comment on table  habilidad                is 'Catálogo de tecnologías y herramientas (PHP, Laravel, Docker...). Se reutiliza en experiencia y proyectos.';
comment on column habilidad.id             is 'Identificador único de la habilidad.';
comment on column habilidad.categoria_id   is 'Categoría a la que pertenece.';
comment on column habilidad.nombre         is 'Nombre de la tecnología o herramienta.';
comment on column habilidad.icono          is 'Nombre del ícono que usará el frontend.';
comment on column habilidad.sitio_web      is 'Sitio oficial de la tecnología.';
comment on column habilidad.activo         is 'Si es falso no aparece en los selectores del administrador.';
comment on column habilidad.creado_en      is 'Fecha de creación del registro.';
comment on column habilidad.actualizado_en is 'Fecha de la última modificación del registro.';

-- 4.2 persona_habilidad ---------------------------------------------------
create table persona_habilidad (
    id                  integer       generated always as identity,
    persona_id          integer       not null,
    habilidad_id        integer       not null,
    nivel_dominio       smallint,
    anios_experiencia   numeric(3,1),
    visible             boolean       not null default true,
    orden               smallint      not null default 0,
    creado_en           timestamptz   not null default now(),
    actualizado_en      timestamptz   not null default now(),
    constraint pk_persona_habilidad         primary key (id),
    constraint uq_persona_habilidad         unique (persona_id, habilidad_id),
    constraint fk_persona_habilidad_persona foreign key (persona_id)   references persona (id)   on delete cascade,
    constraint fk_persona_habilidad_habil   foreign key (habilidad_id) references habilidad (id),
    constraint ck_persona_habilidad_nivel   check (nivel_dominio between 1 and 5),
    constraint ck_persona_habilidad_anios   check (anios_experiencia >= 0)
);
create index idx_persona_habilidad_habilidad_id on persona_habilidad (habilidad_id);

comment on table  persona_habilidad                   is 'Habilidades que domina la persona.';
comment on column persona_habilidad.id                is 'Identificador único del registro.';
comment on column persona_habilidad.persona_id        is 'Persona que posee la habilidad.';
comment on column persona_habilidad.habilidad_id      is 'Habilidad del catálogo.';
comment on column persona_habilidad.nivel_dominio     is 'Nivel de dominio del 1 (básico) al 5 (experto). Opcional.';
comment on column persona_habilidad.anios_experiencia is 'Años de experiencia con la habilidad. Opcional.';
comment on column persona_habilidad.visible           is 'Si es falso no se muestra en el CV público.';
comment on column persona_habilidad.orden             is 'Orden de aparición dentro de su categoría.';
comment on column persona_habilidad.creado_en         is 'Fecha de creación del registro.';
comment on column persona_habilidad.actualizado_en    is 'Fecha de la última modificación del registro.';


-- =============================================================================
-- 5. EXPERIENCIA LABORAL
-- =============================================================================

-- 5.1 empresa -------------------------------------------------------------
create table empresa (
    id              integer       generated always as identity,
    nombre          varchar(150)  not null,
    razon_social    varchar(200),
    sector          varchar(100),
    sitio_web       varchar(300),
    logo_url        varchar(500),
    creado_en       timestamptz   not null default now(),
    actualizado_en  timestamptz   not null default now(),
    constraint pk_empresa        primary key (id),
    constraint uq_empresa_nombre unique (nombre)
);
comment on table  empresa              is 'Empresas o instituciones donde se ha laborado.';
comment on column empresa.id           is 'Identificador único de la empresa.';
comment on column empresa.nombre       is 'Nombre comercial (ej. Cinemex).';
comment on column empresa.razon_social is 'Razón social (ej. Operadora Cinemas SA de CV).';
comment on column empresa.sector       is 'Sector o giro de la empresa.';
comment on column empresa.sitio_web    is 'Sitio web oficial.';
comment on column empresa.logo_url     is 'URL del logotipo.';
comment on column empresa.creado_en    is 'Fecha de creación del registro.';
comment on column empresa.actualizado_en is 'Fecha de la última modificación del registro.';

-- 5.2 experiencia_laboral -------------------------------------------------
-- Cada fila es un PUESTO. Varios puestos pueden compartir empresa (ej. Cinemex).
create table experiencia_laboral (
    id              integer       generated always as identity,
    persona_id      integer       not null,
    empresa_id      integer       not null,
    puesto          varchar(150)  not null,
    descripcion     text,
    fecha_inicio    date          not null,
    fecha_fin       date,
    es_actual       boolean       not null default false,
    visible         boolean       not null default true,
    orden           smallint      not null default 0,
    creado_en       timestamptz   not null default now(),
    actualizado_en  timestamptz   not null default now(),
    constraint pk_experiencia_laboral         primary key (id),
    constraint fk_experiencia_laboral_persona foreign key (persona_id) references persona (id) on delete cascade,
    constraint fk_experiencia_laboral_empresa foreign key (empresa_id) references empresa (id),
    constraint ck_experiencia_laboral_fechas  check (fecha_fin is null or fecha_fin >= fecha_inicio),
    constraint ck_experiencia_laboral_actual  check (not es_actual or fecha_fin is null)
);
create index idx_experiencia_laboral_persona_id on experiencia_laboral (persona_id);
create index idx_experiencia_laboral_empresa_id on experiencia_laboral (empresa_id);

comment on table  experiencia_laboral              is 'Puestos desempeñados. Cada fila es un puesto; una empresa puede tener varios.';
comment on column experiencia_laboral.id           is 'Identificador único de la experiencia.';
comment on column experiencia_laboral.persona_id   is 'Persona que desempeñó el puesto.';
comment on column experiencia_laboral.empresa_id   is 'Empresa donde se desempeñó el puesto.';
comment on column experiencia_laboral.puesto       is 'Nombre del puesto (ej. Desarrollador Full Stack).';
comment on column experiencia_laboral.descripcion  is 'Descripción general de las responsabilidades.';
comment on column experiencia_laboral.fecha_inicio is 'Fecha de inicio. Si solo se conoce el año, usar el 1 de enero.';
comment on column experiencia_laboral.fecha_fin    is 'Fecha de término. Debe ser nula si es el puesto actual.';
comment on column experiencia_laboral.es_actual    is 'Indica si es el puesto actual (se muestra como Presente).';
comment on column experiencia_laboral.visible      is 'Si es falso no se muestra en el CV público.';
comment on column experiencia_laboral.orden        is 'Orden de aparición.';
comment on column experiencia_laboral.creado_en    is 'Fecha de creación del registro.';
comment on column experiencia_laboral.actualizado_en is 'Fecha de la última modificación del registro.';

-- 5.3 experiencia_logro ---------------------------------------------------
create table experiencia_logro (
    id                      integer       generated always as identity,
    experiencia_laboral_id  integer       not null,
    descripcion             varchar(500)  not null,
    orden                   smallint      not null default 0,
    visible                 boolean       not null default true,
    creado_en               timestamptz   not null default now(),
    actualizado_en          timestamptz   not null default now(),
    constraint pk_experiencia_logro            primary key (id),
    constraint fk_experiencia_logro_experiencia foreign key (experiencia_laboral_id)
        references experiencia_laboral (id) on delete cascade
);
create index idx_experiencia_logro_experiencia_id on experiencia_logro (experiencia_laboral_id);

comment on table  experiencia_logro                         is 'Logros clave (viñetas) de una experiencia laboral.';
comment on column experiencia_logro.id                      is 'Identificador único del logro.';
comment on column experiencia_logro.experiencia_laboral_id  is 'Experiencia a la que pertenece el logro.';
comment on column experiencia_logro.descripcion             is 'Texto del logro.';
comment on column experiencia_logro.orden                   is 'Orden de aparición.';
comment on column experiencia_logro.visible                 is 'Si es falso no se muestra en el CV público.';
comment on column experiencia_logro.creado_en               is 'Fecha de creación del registro.';
comment on column experiencia_logro.actualizado_en          is 'Fecha de la última modificación del registro.';

-- 5.4 experiencia_habilidad (tecnologías usadas en el puesto) -------------
create table experiencia_habilidad (
    experiencia_laboral_id  integer  not null,
    habilidad_id            integer  not null,
    constraint pk_experiencia_habilidad primary key (experiencia_laboral_id, habilidad_id),
    constraint fk_experiencia_habilidad_experiencia foreign key (experiencia_laboral_id)
        references experiencia_laboral (id) on delete cascade,
    constraint fk_experiencia_habilidad_habilidad foreign key (habilidad_id)
        references habilidad (id)
);
create index idx_experiencia_habilidad_habilidad_id on experiencia_habilidad (habilidad_id);

comment on table  experiencia_habilidad                        is 'Tecnologías utilizadas en cada experiencia laboral (relación N a N).';
comment on column experiencia_habilidad.experiencia_laboral_id is 'Experiencia laboral.';
comment on column experiencia_habilidad.habilidad_id           is 'Tecnología utilizada.';


-- =============================================================================
-- 6. PROYECTOS
-- =============================================================================

-- 6.1 proyecto ------------------------------------------------------------
create table proyecto (
    id                      integer       generated always as identity,
    persona_id              integer       not null,
    experiencia_laboral_id  integer,
    nombre                  varchar(150)  not null,
    descripcion             text,
    url_demo                varchar(500),
    url_repositorio         varchar(500),
    es_confidencial         boolean       not null default false,
    es_destacado            boolean       not null default false,
    fecha_inicio            date,
    fecha_fin               date,
    visible                 boolean       not null default true,
    orden                   smallint      not null default 0,
    creado_en               timestamptz   not null default now(),
    actualizado_en          timestamptz   not null default now(),
    constraint pk_proyecto              primary key (id),
    constraint fk_proyecto_persona      foreign key (persona_id)             references persona (id)             on delete cascade,
    constraint fk_proyecto_experiencia  foreign key (experiencia_laboral_id) references experiencia_laboral (id) on delete set null,
    constraint ck_proyecto_fechas       check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio)
);
create index idx_proyecto_persona_id     on proyecto (persona_id);
create index idx_proyecto_experiencia_id on proyecto (experiencia_laboral_id);

comment on table  proyecto                         is 'Proyectos destacados de la persona.';
comment on column proyecto.id                      is 'Identificador único del proyecto.';
comment on column proyecto.persona_id              is 'Persona autora del proyecto.';
comment on column proyecto.experiencia_laboral_id  is 'Experiencia laboral en la que se desarrolló (opcional).';
comment on column proyecto.nombre                  is 'Nombre del proyecto.';
comment on column proyecto.descripcion             is 'Descripción del proyecto.';
comment on column proyecto.url_demo                is 'URL de demostración en línea (opcional).';
comment on column proyecto.url_repositorio         is 'URL del repositorio de código (opcional).';
comment on column proyecto.es_confidencial         is 'Indica que el proyecto es interno o confidencial; se omiten enlaces.';
comment on column proyecto.es_destacado            is 'Indica si se resalta en el CV.';
comment on column proyecto.fecha_inicio            is 'Fecha de inicio del proyecto.';
comment on column proyecto.fecha_fin               is 'Fecha de término del proyecto.';
comment on column proyecto.visible                 is 'Si es falso no se muestra en el CV público.';
comment on column proyecto.orden                   is 'Orden de aparición.';
comment on column proyecto.creado_en               is 'Fecha de creación del registro.';
comment on column proyecto.actualizado_en          is 'Fecha de la última modificación del registro.';

-- 6.2 proyecto_habilidad --------------------------------------------------
create table proyecto_habilidad (
    proyecto_id   integer  not null,
    habilidad_id  integer  not null,
    constraint pk_proyecto_habilidad          primary key (proyecto_id, habilidad_id),
    constraint fk_proyecto_habilidad_proyecto foreign key (proyecto_id)  references proyecto (id)  on delete cascade,
    constraint fk_proyecto_habilidad_habil    foreign key (habilidad_id) references habilidad (id)
);
create index idx_proyecto_habilidad_habilidad_id on proyecto_habilidad (habilidad_id);

comment on table  proyecto_habilidad              is 'Tecnologías utilizadas en cada proyecto (relación N a N).';
comment on column proyecto_habilidad.proyecto_id  is 'Proyecto.';
comment on column proyecto_habilidad.habilidad_id is 'Tecnología utilizada.';


-- =============================================================================
-- 7. EDUCACIÓN, CERTIFICACIONES Y PUBLICACIONES
-- =============================================================================

-- 7.1 institucion_educativa -----------------------------------------------
create table institucion_educativa (
    id              integer       generated always as identity,
    nombre          varchar(200)  not null,
    siglas          varchar(30),
    sitio_web       varchar(300),
    pais_id         smallint,
    creado_en       timestamptz   not null default now(),
    actualizado_en  timestamptz   not null default now(),
    constraint pk_institucion_educativa        primary key (id),
    constraint uq_institucion_educativa_nombre unique (nombre),
    constraint fk_institucion_educativa_pais   foreign key (pais_id) references pais (id)
);
create index idx_institucion_educativa_pais_id on institucion_educativa (pais_id);

comment on table  institucion_educativa           is 'Instituciones que imparten estudios o certificaciones.';
comment on column institucion_educativa.id        is 'Identificador único de la institución.';
comment on column institucion_educativa.nombre    is 'Nombre completo (ej. Benemérita Universidad Autónoma de Puebla).';
comment on column institucion_educativa.siglas    is 'Siglas (ej. BUAP).';
comment on column institucion_educativa.sitio_web is 'Sitio web oficial.';
comment on column institucion_educativa.pais_id   is 'País de la institución.';
comment on column institucion_educativa.creado_en is 'Fecha de creación del registro.';
comment on column institucion_educativa.actualizado_en is 'Fecha de la última modificación del registro.';

-- 7.2 educacion -----------------------------------------------------------
create table educacion (
    id                        integer       generated always as identity,
    persona_id                integer       not null,
    institucion_educativa_id  integer       not null,
    nivel_academico_id        smallint      not null,
    titulo                    varchar(200)  not null,
    campo_estudio             varchar(150),
    fecha_inicio              date,
    fecha_fin                 date,
    en_curso                  boolean       not null default false,
    visible                   boolean       not null default true,
    orden                     smallint      not null default 0,
    creado_en                 timestamptz   not null default now(),
    actualizado_en            timestamptz   not null default now(),
    constraint pk_educacion              primary key (id),
    constraint fk_educacion_persona      foreign key (persona_id)               references persona (id)               on delete cascade,
    constraint fk_educacion_institucion  foreign key (institucion_educativa_id) references institucion_educativa (id),
    constraint fk_educacion_nivel        foreign key (nivel_academico_id)       references nivel_academico (id),
    constraint ck_educacion_fechas       check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio)
);
create index idx_educacion_persona_id     on educacion (persona_id);
create index idx_educacion_institucion_id on educacion (institucion_educativa_id);
create index idx_educacion_nivel_id       on educacion (nivel_academico_id);

comment on table  educacion                          is 'Formación académica de la persona.';
comment on column educacion.id                       is 'Identificador único del registro.';
comment on column educacion.persona_id               is 'Persona que cursó los estudios.';
comment on column educacion.institucion_educativa_id is 'Institución donde se cursaron.';
comment on column educacion.nivel_academico_id       is 'Nivel académico (licenciatura, maestría...).';
comment on column educacion.titulo                   is 'Título obtenido o programa cursado.';
comment on column educacion.campo_estudio            is 'Área o disciplina de estudio.';
comment on column educacion.fecha_inicio             is 'Fecha de inicio. Si solo se conoce el año, usar el 1 de enero.';
comment on column educacion.fecha_fin                is 'Fecha de término.';
comment on column educacion.en_curso                 is 'Indica si los estudios siguen en curso.';
comment on column educacion.visible                  is 'Si es falso no se muestra en el CV público.';
comment on column educacion.orden                    is 'Orden de aparición.';
comment on column educacion.creado_en                is 'Fecha de creación del registro.';
comment on column educacion.actualizado_en           is 'Fecha de la última modificación del registro.';

-- 7.3 certificacion -------------------------------------------------------
create table certificacion (
    id                        integer       generated always as identity,
    persona_id                integer       not null,
    institucion_educativa_id  integer,
    nombre                    varchar(200)  not null,
    fecha_emision             date,
    fecha_vencimiento         date,
    codigo_credencial         varchar(100),
    url_credencial            varchar(500),
    visible                   boolean       not null default true,
    orden                     smallint      not null default 0,
    creado_en                 timestamptz   not null default now(),
    actualizado_en            timestamptz   not null default now(),
    constraint pk_certificacion             primary key (id),
    constraint fk_certificacion_persona     foreign key (persona_id)               references persona (id)               on delete cascade,
    constraint fk_certificacion_institucion foreign key (institucion_educativa_id) references institucion_educativa (id),
    constraint ck_certificacion_fechas      check (fecha_vencimiento is null or fecha_emision is null or fecha_vencimiento >= fecha_emision)
);
create index idx_certificacion_persona_id     on certificacion (persona_id);
create index idx_certificacion_institucion_id on certificacion (institucion_educativa_id);

comment on table  certificacion                    is 'Certificaciones y cursos con credencial.';
comment on column certificacion.id                 is 'Identificador único de la certificación.';
comment on column certificacion.persona_id         is 'Persona que obtuvo la certificación.';
comment on column certificacion.institucion_educativa_id is 'Entidad emisora (opcional).';
comment on column certificacion.nombre             is 'Nombre de la certificación.';
comment on column certificacion.fecha_emision      is 'Fecha de emisión.';
comment on column certificacion.fecha_vencimiento  is 'Fecha de vencimiento (nula si no vence).';
comment on column certificacion.codigo_credencial  is 'Código o identificador de la credencial.';
comment on column certificacion.url_credencial     is 'URL para verificar la credencial.';
comment on column certificacion.visible            is 'Si es falso no se muestra en el CV público.';
comment on column certificacion.orden              is 'Orden de aparición.';
comment on column certificacion.creado_en          is 'Fecha de creación del registro.';
comment on column certificacion.actualizado_en     is 'Fecha de la última modificación del registro.';

-- 7.4 publicacion ---------------------------------------------------------
create table publicacion (
    id                  integer       generated always as identity,
    persona_id          integer       not null,
    titulo              varchar(300)  not null,
    medio               varchar(250),
    referencia          varchar(250),
    fecha_publicacion   date,
    url                 varchar(1000),
    descripcion         text,
    visible             boolean       not null default true,
    orden               smallint      not null default 0,
    creado_en           timestamptz   not null default now(),
    actualizado_en      timestamptz   not null default now(),
    constraint pk_publicacion         primary key (id),
    constraint fk_publicacion_persona foreign key (persona_id) references persona (id) on delete cascade
);
create index idx_publicacion_persona_id on publicacion (persona_id);

comment on table  publicacion                    is 'Publicaciones y contribuciones (libros, artículos, capítulos).';
comment on column publicacion.id                 is 'Identificador único de la publicación.';
comment on column publicacion.persona_id         is 'Persona autora.';
comment on column publicacion.titulo             is 'Título de la publicación.';
comment on column publicacion.medio              is 'Libro, revista o medio donde se publicó.';
comment on column publicacion.referencia         is 'Referencia puntual (ej. Capítulo 7, página 88).';
comment on column publicacion.fecha_publicacion  is 'Fecha de publicación. Si solo se conoce el año, usar el 1 de enero.';
comment on column publicacion.url                is 'Enlace a la publicación.';
comment on column publicacion.descripcion        is 'Resumen o comentario adicional.';
comment on column publicacion.visible            is 'Si es falso no se muestra en el CV público.';
comment on column publicacion.orden              is 'Orden de aparición.';
comment on column publicacion.creado_en          is 'Fecha de creación del registro.';
comment on column publicacion.actualizado_en     is 'Fecha de la última modificación del registro.';


-- =============================================================================
-- 8. ANALÍTICA (diseñada para no exceder los 500 MB del plan gratuito)
--    Estrategia:
--      1) Eventos crudos (sesion_visita, evento_cv): tablas angostas, sin IP ni
--         datos personales, con retención corta (90 días por defecto).
--      2) estadistica_diaria: resumen agregado por día que se conserva siempre
--         y ocupa muy poco espacio.
-- =============================================================================

-- 8.1 sesion_visita -------------------------------------------------------
create table sesion_visita (
    id                 bigint       generated always as identity,
    cv_id              integer      not null,
    visitante_hash     varchar(64)  not null,
    iniciada_en        timestamptz  not null default now(),
    pais_codigo        char(2),
    dispositivo        varchar(20)  not null default 'OTRO',
    navegador          varchar(40),
    sistema_operativo  varchar(40),
    origen_referencia  varchar(255),
    utm_fuente         varchar(100),
    utm_medio          varchar(100),
    utm_campania       varchar(100),
    es_bot             boolean      not null default false,
    constraint pk_sesion_visita    primary key (id),
    constraint fk_sesion_visita_cv foreign key (cv_id) references cv (id) on delete cascade,
    constraint ck_sesion_visita_dispositivo check (dispositivo in ('ESCRITORIO', 'MOVIL', 'TABLET', 'OTRO'))
);
create index idx_sesion_visita_cv_fecha on sesion_visita (cv_id, iniciada_en);

comment on table  sesion_visita                   is 'Sesión de un visitante al CV público. No almacena IP ni datos personales.';
comment on column sesion_visita.id                is 'Identificador único de la sesión.';
comment on column sesion_visita.cv_id             is 'CV consultado.';
comment on column sesion_visita.visitante_hash    is 'Hash SHA-256 (con sal) de IP + user agent, calculado en el backend. Permite contar visitantes únicos sin guardar la IP.';
comment on column sesion_visita.iniciada_en       is 'Fecha y hora de inicio de la sesión.';
comment on column sesion_visita.pais_codigo       is 'País del visitante (ISO alfa-2), si se pudo determinar.';
comment on column sesion_visita.dispositivo       is 'Tipo de dispositivo: ESCRITORIO, MOVIL, TABLET u OTRO.';
comment on column sesion_visita.navegador         is 'Navegador del visitante.';
comment on column sesion_visita.sistema_operativo is 'Sistema operativo del visitante.';
comment on column sesion_visita.origen_referencia is 'Dominio desde el que llegó el visitante (ej. linkedin.com).';
comment on column sesion_visita.utm_fuente        is 'Parámetro utm_source de la URL.';
comment on column sesion_visita.utm_medio         is 'Parámetro utm_medium de la URL.';
comment on column sesion_visita.utm_campania      is 'Parámetro utm_campaign de la URL.';
comment on column sesion_visita.es_bot            is 'Indica si se detectó como bot o rastreador. Se excluye de las estadísticas.';

-- 8.2 evento_cv -----------------------------------------------------------
create table evento_cv (
    id                 bigint       generated always as identity,
    sesion_visita_id   bigint       not null,
    tipo_evento_id     smallint     not null,
    elemento_tipo      varchar(30),
    elemento_id        integer,
    etiqueta           varchar(300),
    ocurrio_en         timestamptz  not null default now(),
    constraint pk_evento_cv        primary key (id),
    constraint fk_evento_cv_sesion foreign key (sesion_visita_id) references sesion_visita (id) on delete cascade,
    constraint fk_evento_cv_tipo   foreign key (tipo_evento_id)   references tipo_evento (id)
);
create index idx_evento_cv_sesion_id on evento_cv (sesion_visita_id);
-- BRIN: índice minúsculo, ideal para tablas que solo crecen por fecha
create index idx_evento_cv_ocurrio_en_brin on evento_cv using brin (ocurrio_en);

comment on table  evento_cv                  is 'Evento individual dentro de una sesión (vista, clic, descarga). Se purga tras N días.';
comment on column evento_cv.id               is 'Identificador único del evento.';
comment on column evento_cv.sesion_visita_id is 'Sesión a la que pertenece el evento.';
comment on column evento_cv.tipo_evento_id   is 'Tipo de evento ocurrido.';
comment on column evento_cv.elemento_tipo    is 'Tipo de elemento afectado (ej. PROYECTO, CONTACTO, SECCION, ENLACE).';
comment on column evento_cv.elemento_id      is 'Id del elemento afectado (ej. proyecto.id o persona_contacto.id).';
comment on column evento_cv.etiqueta         is 'Detalle libre: URL de destino, nombre de sección, etc.';
comment on column evento_cv.ocurrio_en       is 'Fecha y hora en que ocurrió el evento.';

-- 8.3 estadistica_diaria --------------------------------------------------
create table estadistica_diaria (
    cv_id              integer      not null,
    fecha              date         not null,
    tipo_evento_id     smallint     not null,
    elemento_tipo      varchar(30)  not null default '',
    elemento_id        integer      not null default 0,
    total_eventos      integer      not null default 0,
    visitantes_unicos  integer      not null default 0,
    actualizado_en     timestamptz  not null default now(),
    constraint pk_estadistica_diaria primary key (cv_id, fecha, tipo_evento_id, elemento_tipo, elemento_id),
    constraint fk_estadistica_diaria_cv   foreign key (cv_id)          references cv (id) on delete cascade,
    constraint fk_estadistica_diaria_tipo foreign key (tipo_evento_id) references tipo_evento (id)
);
create index idx_estadistica_diaria_tipo_id on estadistica_diaria (tipo_evento_id);

comment on table  estadistica_diaria                   is 'Resumen diario agregado de eventos. Se conserva indefinidamente (ocupa muy poco).';
comment on column estadistica_diaria.cv_id             is 'CV al que corresponde la estadística.';
comment on column estadistica_diaria.fecha             is 'Día calculado en zona horaria America/Mexico_City.';
comment on column estadistica_diaria.tipo_evento_id    is 'Tipo de evento agregado.';
comment on column estadistica_diaria.elemento_tipo     is 'Tipo de elemento afectado. Cadena vacía si no aplica.';
comment on column estadistica_diaria.elemento_id       is 'Id del elemento afectado. 0 si no aplica.';
comment on column estadistica_diaria.total_eventos     is 'Número total de eventos del día.';
comment on column estadistica_diaria.visitantes_unicos is 'Visitantes distintos que generaron el evento en el día.';
comment on column estadistica_diaria.actualizado_en    is 'Fecha de la última consolidación.';


-- =============================================================================
-- 9. FUNCIONES DE MANTENIMIENTO DE ANALÍTICA
-- =============================================================================

-- 9.1 Consolida los eventos crudos de un día en estadistica_diaria (idempotente)
create or replace function fn_consolidar_estadistica_diaria(
    p_fecha date default ((now() at time zone 'America/Mexico_City')::date - 1)
)
returns integer
language plpgsql
as $$
declare
    v_desde timestamptz := p_fecha::timestamp at time zone 'America/Mexico_City';
    v_hasta timestamptz := (p_fecha + 1)::timestamp at time zone 'America/Mexico_City';
    v_filas integer;
begin
    insert into estadistica_diaria (
        cv_id, fecha, tipo_evento_id, elemento_tipo, elemento_id,
        total_eventos, visitantes_unicos
    )
    select s.cv_id,
           p_fecha,
           e.tipo_evento_id,
           coalesce(e.elemento_tipo, ''),
           coalesce(e.elemento_id, 0),
           count(*),
           count(distinct s.visitante_hash)
      from evento_cv e
      join sesion_visita s on s.id = e.sesion_visita_id
     where e.ocurrio_en >= v_desde
       and e.ocurrio_en <  v_hasta
       and not s.es_bot
     group by s.cv_id, e.tipo_evento_id, coalesce(e.elemento_tipo, ''), coalesce(e.elemento_id, 0)
    on conflict (cv_id, fecha, tipo_evento_id, elemento_tipo, elemento_id)
    do update set total_eventos     = excluded.total_eventos,
                  visitantes_unicos = excluded.visitantes_unicos,
                  actualizado_en    = now();

    get diagnostics v_filas = row_count;
    return v_filas;
end;
$$;
comment on function fn_consolidar_estadistica_diaria(date)
    is 'Agrega los eventos de un día (por defecto ayer, hora de México) en estadistica_diaria. Devuelve las filas afectadas.';

-- 9.2 Elimina sesiones (y sus eventos por cascada) anteriores a N días
create or replace function fn_purgar_eventos_antiguos(p_dias integer default 90)
returns integer
language plpgsql
as $$
declare
    v_filas integer;
begin
    if p_dias < 7 then
        raise exception 'La retención mínima permitida es de 7 días (recibido: %).', p_dias;
    end if;

    delete from sesion_visita
     where iniciada_en < now() - make_interval(days => p_dias);

    get diagnostics v_filas = row_count;
    return v_filas;
end;
$$;
comment on function fn_purgar_eventos_antiguos(integer)
    is 'Borra sesiones y eventos con más de p_dias de antigüedad. Ejecutar siempre después de consolidar.';


-- =============================================================================
-- 10. TRIGGERS DE AUDITORÍA (actualizado_en en todas las tablas que lo tengan)
-- =============================================================================
do $$
declare
    v_tabla record;
begin
    for v_tabla in
        select c.table_name
          from information_schema.columns c
          join pg_tables t on t.schemaname = c.table_schema and t.tablename = c.table_name
         where c.table_schema = 'public'
           and c.column_name  = 'actualizado_en'
    loop
        execute format(
            'create trigger %I before update on public.%I
             for each row execute function fn_actualizar_fecha_modificacion()',
            'trg_' || v_tabla.table_name || '_actualizado_en',
            v_tabla.table_name
        );
    end loop;
end;
$$;


-- =============================================================================
-- 11. VISTAS (security_invoker respeta los permisos de quien consulta)
-- =============================================================================

create or replace view vw_persona with (security_invoker = true) as
select p.id,
       p.usuario_id,
       p.nombre,
       p.apellido_paterno,
       p.apellido_materno,
       p.nombre_completo,
       p.fecha_nacimiento,
       fn_calcular_edad(p.fecha_nacimiento) as edad,
       p.titulo_profesional,
       p.foto_url,
       p.ciudad,
       p.estado,
       pa.nombre as pais
  from persona p
  left join pais pa on pa.id = p.pais_id;
comment on view vw_persona is 'Persona con edad calculada y nombre del país.';

create or replace view vw_estadistica_cv_diaria with (security_invoker = true) as
select ed.cv_id,
       ed.fecha,
       coalesce(sum(ed.total_eventos)     filter (where te.codigo = 'VISTA_CV'), 0)     as vistas,
       coalesce(max(ed.visitantes_unicos) filter (where te.codigo = 'VISTA_CV'), 0)     as visitantes_unicos,
       coalesce(sum(ed.total_eventos)     filter (where te.codigo like 'CLIC%'), 0)     as clics,
       coalesce(sum(ed.total_eventos)     filter (where te.codigo = 'DESCARGA_PDF'), 0) as descargas_pdf
  from estadistica_diaria ed
  join tipo_evento te on te.id = ed.tipo_evento_id
 group by ed.cv_id, ed.fecha;
comment on view vw_estadistica_cv_diaria is 'KPIs diarios por CV: vistas, visitantes únicos, clics y descargas de PDF.';

create or replace view vw_clics_por_elemento with (security_invoker = true) as
select ed.cv_id,
       te.codigo        as tipo_evento,
       ed.elemento_tipo,
       ed.elemento_id,
       sum(ed.total_eventos) as total_clics,
       min(ed.fecha)         as primera_fecha,
       max(ed.fecha)         as ultima_fecha
  from estadistica_diaria ed
  join tipo_evento te on te.id = ed.tipo_evento_id
 where te.codigo like 'CLIC%' or te.codigo = 'DESCARGA_PDF'
 group by ed.cv_id, te.codigo, ed.elemento_tipo, ed.elemento_id;
comment on view vw_clics_por_elemento is 'Total histórico de clics y descargas por elemento (proyecto, enlace, contacto).';


-- =============================================================================
-- 12. SEGURIDAD EN SUPABASE
--     Supabase expone las tablas del esquema public vía API REST (PostgREST).
--     Se activa RLS sin políticas y se revocan permisos a anon/authenticated:
--     la API pública queda cerrada y solo tu backend Spring Boot (que se conecta
--     con el rol postgres y omite RLS) puede leer y escribir.
-- =============================================================================
do $$
declare
    v_tabla record;
begin
    for v_tabla in select tablename from pg_tables where schemaname = 'public' loop
        execute format('alter table public.%I enable row level security', v_tabla.tablename);
    end loop;
end;
$$;

revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated;


-- =============================================================================
-- 13. DATOS INICIALES DE CATÁLOGOS
-- =============================================================================

insert into rol (codigo, nombre, descripcion) values
    ('ADMIN',  'Administrador', 'Acceso total al administrador del CV.'),
    ('LECTOR', 'Lector',        'Acceso de solo lectura.');

insert into pais (codigo_iso, nombre) values
    ('MX', 'México'), ('US', 'Estados Unidos'), ('ES', 'España'),
    ('CO', 'Colombia'), ('AR', 'Argentina'), ('CL', 'Chile'), ('PE', 'Perú');

insert into idioma (codigo, nombre) values
    ('es', 'Español'), ('en', 'Inglés');

insert into nivel_idioma (codigo, nombre, orden) values
    ('A1', 'Principiante', 1), ('A2', 'Elemental', 2),
    ('B1', 'Intermedio', 3),   ('B2', 'Intermedio alto', 4),
    ('C1', 'Avanzado', 5),     ('C2', 'Maestría', 6),
    ('NATIVO', 'Nativo', 7);

insert into nivel_academico (codigo, nombre, orden) values
    ('BACHILLERATO', 'Bachillerato', 1), ('TECNICO', 'Técnico', 2),
    ('LICENCIATURA', 'Licenciatura', 3), ('ESPECIALIDAD', 'Especialidad', 4),
    ('MAESTRIA', 'Maestría', 5),         ('DOCTORADO', 'Doctorado', 6),
    ('DIPLOMADO', 'Diplomado', 7),       ('CURSO', 'Curso', 8);

insert into tipo_contacto (codigo, nombre, icono) values
    ('CORREO', 'Correo electrónico', 'mdi-email'),
    ('TELEFONO', 'Teléfono', 'mdi-phone'),
    ('LINKEDIN', 'LinkedIn', 'mdi-linkedin'),
    ('GITHUB', 'GitHub', 'mdi-github'),
    ('PORTAFOLIO', 'Portafolio', 'mdi-briefcase'),
    ('SITIO_WEB', 'Sitio web', 'mdi-web');

insert into tipo_seccion (codigo, nombre) values
    ('PERFIL', 'Perfil profesional'), ('EXPERIENCIA', 'Experiencia laboral'),
    ('PROYECTOS', 'Proyectos destacados'), ('HABILIDADES', 'Habilidades técnicas'),
    ('EDUCACION', 'Educación'), ('CERTIFICACIONES', 'Certificaciones'),
    ('PUBLICACIONES', 'Publicaciones y contribuciones'), ('IDIOMAS', 'Idiomas');

insert into categoria_habilidad (nombre, orden) values
    ('Lenguajes', 1), ('Frameworks', 2), ('Bases de Datos', 3), ('Herramientas', 4);

insert into tipo_evento (codigo, nombre) values
    ('VISTA_CV',      'Visualización del CV'),
    ('VISTA_SECCION', 'Visualización de una sección'),
    ('CLIC_ENLACE',   'Clic en un enlace externo'),
    ('CLIC_CONTACTO', 'Clic en un medio de contacto'),
    ('CLIC_PROYECTO', 'Clic en un proyecto'),
    ('DESCARGA_PDF',  'Descarga del CV en PDF');

commit;


-- =============================================================================
-- 14. (OPCIONAL) AUTOMATIZACIÓN CON pg_cron
--     Activar primero en Supabase: Database > Extensions > pg_cron.
--     Horarios en UTC (México centro = UTC-6): 06:10 UTC = 00:10 hora local.
-- =============================================================================
-- create extension if not exists pg_cron;
--
-- select cron.schedule('consolidar-estadistica-diaria', '10 6 * * *',
--                      $$ select fn_consolidar_estadistica_diaria(); $$);
--
-- select cron.schedule('purgar-eventos-antiguos', '30 6 * * 0',
--                      $$ select fn_purgar_eventos_antiguos(90); $$);