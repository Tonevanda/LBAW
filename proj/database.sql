create schema if not exists lbaw2315;

-- DROP TABLES

DROP TABLE IF EXISTS review_report;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS product_category;
DROP TABLE IF EXISTS product_statistic;
DROP TABLE IF EXISTS purchase_product;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS wishlist;
DROP TABLE IF EXISTS shopping_cart;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS authenticated_notification;
DROP TABLE IF EXISTS unblock_appeal;
DROP TABLE IF EXISTS wallet;
DROP TABLE IF EXISTS authenticated;
DROP TABLE IF EXISTS admin;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS statistic;
DROP TABLE IF EXISTS stage;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS currency;
DROP TABLE IF EXISTS notification;

-- TABLES

CREATE TABLE notification(
    notification_type TEXT PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE currency(
    currency_type TEXT PRIMARY KEY
);

CREATE TABLE payment(
    payment_type TEXT PRIMARY KEY
);

CREATE TABLE stage(
    stage_state TEXT PRIMARY KEY
);

CREATE TABLE statistic(
    statistic_type TEXT PRIMARY KEY
);

CREATE TABLE category(
    category_type TEXT PRIMARY KEY
);

CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    email TEXT NOT NULL CONSTRAINT email_ck UNIQUE,
    profile_picture TEXT DEFAULT 'df_user_image' NOT NULL --depois quando se faz o pedido à db concatenamos .png no final
);

CREATE TABLE admin(
    admin_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE authenticated(
    user_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE,
    address TEXT,
    isBlocked BOOLEAN DEFAULT FALSE
);


CREATE TABLE wallet(
    user_id INTEGER PRIMARY KEY REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    money INTEGER DEFAULT 0,
    currency_type TEXT NOT NULL REFERENCES currency (currency_type) ON UPDATE CASCADE,
    transaction_date TIMESTAMP WITH TIME ZONE
);


CREATE TABLE unblock_appeal(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);


CREATE TABLE authenticated_notification(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    notification_type TEXT REFERENCES notification (notification_type) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    isNew BOOLEAN DEFAULT FALSE NOT NULL
);

CREATE TABLE product(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    synopsis TEXT NOT NULL,
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price >= 0),
    discount INTEGER DEFAULT 0 CONSTRAINT discount_ck CHECK (discount < price),
    stock INTEGER NOT NULL CONSTRAINT stock_ck CHECK (stock >= 0),
    author TEXT DEFAULT 'anonymous' NOT NULL,
    editor TEXT DEFAULT 'self published' NOT NULL,
    language TEXT NOT NULL,
    image TEXT DEFAULT 'df_product_image' NOT NULL
);

CREATE TABLE shopping_cart(
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE wishlist(
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE purchase(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    price INTEGER NOT NULL,
    quantity INTEGER NOT NULL CONSTRAINT quantity_ck CHECK (quantity > 0),
    payment_type TEXT NOT NULL REFERENCES payment (payment_type) ON UPDATE CASCADE,
    destination TEXT NOT NULL,
    stage_state TEXT NOT NULL REFERENCES stage (stage_state) ON UPDATE CASCADE,
    orderedAt TIMESTAMP WITH TIME ZONE NOT NULL,
    orderArrivedAt TIMESTAMP WITH TIME ZONE NOT NULL CONSTRAINT order_ck CHECK (orderArrivedAt > orderedAt) 
);


CREATE TABLE purchase_product(
    purchase_id INTEGER REFERENCES purchase (id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    quantity INTEGER NOT NULL CONSTRAINT quantity_ck CHECK (quantity > 0),
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price > 0),
    PRIMARY KEY (purchase_id, product_id)
);


CREATE TABLE product_statistic(
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    statistic_type TEXT REFERENCES statistic (statistic_type) ON UPDATE CASCADE,
    result INTEGER NOT NULL,
    PRIMARY KEY (product_id, statistic_type)
);


CREATE TABLE product_category(
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    category_type TEXT REFERENCES category (category_type) ON UPDATE CASCADE,
    PRIMARY KEY (product_id, category_type)
);

CREATE TABLE review(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id) ON UPDATE CASCADE,
    product_id INTEGER NOT NULL REFERENCES product (id) ON UPDATE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    rating INTEGER CONSTRAINT rating_ck CHECK (((0 <= rating) AND (rating <= 5))),
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE review_report(
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES review (id) ON UPDATE CASCADE,
    motive TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

--INDEXES

CREATE INDEX orderedAt_purchase ON purchase USING btree (orderedAt);

CREATE INDEX product_review ON review USING hash (product_id);

CREATE INDEX purchase_user_id ON purchase USING hash (user_id);

-- FTS INDEXES

ALTER TABLE product
ADD COLUMN tsvectors TSVECTOR;       

CREATE OR REPLACE FUNCTION product_FTS_update() RETURNS TRIGGER AS $$
BEGIN
 IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = (
         setweight(to_tsvector('english', NEW.title), 'A') ||
         setweight(to_tsvector('english', NEW.author), 'B')||
         setweight(to_tsvector('english', NEW.editor), 'C')||
         setweight(to_tsvector('english', NEW.synopsis), 'D')
        );
 END IF;
 IF TG_OP = 'UPDATE' THEN
         IF (NEW.title <> OLD.title OR NEW.obs <> OLD.obs) THEN
           NEW.tsvectors = (
             setweight(to_tsvector('english', NEW.title), 'A') ||
             setweight(to_tsvector('english', NEW.obs), 'B')
           );
         END IF;
 END IF;
 RETURN NEW;
END $$
LANGUAGE plpgsql;

CREATE TRIGGER product_FTS_update_trigger
 BEFORE INSERT OR UPDATE ON product
 FOR EACH ROW
 EXECUTE PROCEDURE product_FTS_update();


CREATE INDEX fts_index ON product USING GIN (tsvectors);

CREATE OR REPLACE FUNCTION manage_deleted_account() RETURNS TRIGGER AS
$BODY$
BEGIN
        UPDATE users
        SET name = 'Deleted Account', profile_picture = '../images/default_images/default_user_image'
    
        WHERE users.id = OLD.user_id;
        RETURN OLD;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER manage_deleted_account_trigger
        BEFORE DELETE ON authenticated
        FOR EACH ROW
        EXECUTE PROCEDURE manage_deleted_account();

CREATE OR REPLACE FUNCTION check_admin_purchase() RETURNS TRIGGER AS
$BODY$
BEGIN
        IF EXISTS (SELECT * FROM purchase WHERE NEW.user_id = user_id) THEN
            RAISE EXCEPTION 'An administrator can not make a purchase';
        END IF;
        RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER check_admin_purchase_trigger
        BEFORE INSERT OR UPDATE ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE check_admin_purchase();



