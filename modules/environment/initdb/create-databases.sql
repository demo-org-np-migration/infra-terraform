-- Se ejecuta una sola vez, cuando el volumen de datos está vacío (comportamiento
-- del entrypoint oficial de postgres para todo lo que cuelga de
-- /docker-entrypoint-initdb.d). Al ser .sql, el entrypoint lo corre directo con
-- psql: nada de heredocs de bash anidados con el heredoc de Terraform, que fue
-- justo lo que rompía esto antes (el dedent de Terraform le movía la
-- indentación al delimitador EOSQL y bash nunca cerraba el heredoc).
CREATE DATABASE ledger;
CREATE DATABASE payments;
CREATE DATABASE cards;
CREATE DATABASE rates;
CREATE DATABASE warehouse;
CREATE DATABASE notifications;
