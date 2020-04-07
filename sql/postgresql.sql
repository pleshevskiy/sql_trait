CREATE EXTENSION hstore;


CREATE OR REPLACE FUNCTION manage_trait(_table regclass, _trait_table regclass) RETURNS void AS
$$
BEGIN
    EXECUTE format('ALTER TABLE %s ADD COLUMN %s_id text NOT NULL REFERENCES %s (id)', _table, _trait_table,
                   _trait_table);

    EXECUTE format(E'CREATE TRIGGER create_%s_trait BEFORE INSERT ON %s
                     FOR EACH ROW EXECUTE PROCEDURE trait(\'%s\')',
                   _table, _table, _trait_table);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trait() RETURNS trigger AS
$$
DECLARE
    trait_table varchar(128);
BEGIN
    trait_table := tg_argv[0];

    EXECUTE format(E'INSERT INTO %s.%s (id) VALUES (\'%s_%s\')', tg_table_schema, trait_table, tg_table_name, new.id);
    EXECUTE format(E'SELECT ($1 #= hstore(\'%s_id\', \'%s_\' || $1.id)).*', trait_table, tg_table_name)
        USING new
        INTO new;
    RETURN new;

END;
$$ LANGUAGE plpgsql;


CREATE TABLE identities
(
    id       serial PRIMARY KEY,
    email    varchar(255) NOT NULL,
    password varchar(255) NOT NULL
);


CREATE TABLE users
(
    id          serial PRIMARY KEY,
    identity_id int NOT NULL REFERENCES identities(id),
    fullname    varchar(255),
    bio         varchar(2048)
);


CREATE TABLE likes_trait
(
    id text PRIMARY KEY
);


CREATE TABLE likes
(
    identity_id    int REFERENCES identities (id),
    likes_trait_id text REFERENCES likes_trait (id),
    is_like        bool,

    PRIMARY KEY (identity_id, likes_trait_id)
);


CREATE TABLE articles
(
    id    serial PRIMARY KEY,
    title text NOT NULL
);

SELECT manage_trait('articles', 'likes_trait');


CREATE TABLE recipes_test
(
    id    serial PRIMARY KEY,
    title text NOT NULL
);

SELECT manage_trait('recipes_test', 'likes_trait');
