DROP SCHEMA IF EXISTS lbaw2315 CASCADE;

CREATE SCHEMA lbaw2315;

SET search_path TO lbaw2315;




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
    profile_picture TEXT DEFAULT 'df_user_img.png' NOT NULL 
);

CREATE TABLE admin(
    admin_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE authenticated(
    user_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    address TEXT,
    isBlocked BOOLEAN DEFAULT FALSE NOT NULL
);


CREATE TABLE wallet(
    user_id INTEGER PRIMARY KEY REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    money INTEGER DEFAULT 0 NOT NULL,
    currency_type TEXT NOT NULL REFERENCES currency (currency_type) ON UPDATE CASCADE ON DELETE CASCADE,
    transaction_date TIMESTAMP WITH TIME ZONE
);


CREATE TABLE unblock_appeal(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);


CREATE TABLE authenticated_notification(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    notification_type TEXT REFERENCES notification (notification_type) ON UPDATE CASCADE ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    isNew BOOLEAN DEFAULT TRUE  NOT NULL
);

CREATE TABLE product(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    synopsis TEXT NOT NULL,
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price >= 0),
    discount INTEGER DEFAULT 0 NOT NULL CONSTRAINT discount_ck CHECK (discount <= price),
    stock INTEGER NOT NULL CONSTRAINT stock_ck CHECK (stock >= 0),
    author TEXT DEFAULT 'anonymous' NOT NULL,
    editor TEXT DEFAULT 'self published' NOT NULL,
    language TEXT NOT NULL,
    image TEXT DEFAULT 'df_product_img.png' NOT NULL,
    orderStatus INTEGER NOT NULL DEFAULT 0 CONSTRAINT orderStatus_ck CHECK (orderStatus >= 0)
);

CREATE TABLE shopping_cart(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE wishlist(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE purchase(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    price INTEGER NOT NULL,
    quantity INTEGER NOT NULL CONSTRAINT quantity_ck CHECK (quantity > 0),
    payment_type TEXT NOT NULL REFERENCES payment (payment_type) ON UPDATE CASCADE ON DELETE CASCADE,
    destination TEXT NOT NULL,
    stage_state TEXT NOT NULL REFERENCES stage (stage_state) ON UPDATE CASCADE ON DELETE CASCADE,
    isTracked BOOLEAN DEFAULT FALSE NOT NULL,
    orderedAt TIMESTAMP WITH TIME ZONE NOT NULL,
    orderArrivedAt TIMESTAMP WITH TIME ZONE NOT NULL CONSTRAINT order_ck CHECK (orderArrivedAt > orderedAt) 
);


CREATE TABLE purchase_product(
    id SERIAL PRIMARY KEY,
    purchase_id INTEGER REFERENCES purchase (id) ON UPDATE CASCADE ON DELETE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE,
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price >= 0)
);


CREATE TABLE product_statistic(
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE,
    statistic_type TEXT REFERENCES statistic (statistic_type) ON UPDATE CASCADE ON DELETE CASCADE,
    result INTEGER DEFAULT 0 NOT NULL,
    stat INTEGER DEFAULT 0 NOT NULL,
    PRIMARY KEY (product_id, statistic_type)
);


CREATE TABLE product_category(
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE,
    category_type TEXT REFERENCES category (category_type) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_type)
);

CREATE TABLE review(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id) ON UPDATE CASCADE,
    product_id INTEGER NOT NULL REFERENCES product (id) ON UPDATE CASCADE ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    rating INTEGER CONSTRAINT rating_ck CHECK (((0 <= rating) AND (rating <= 5))),
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT user_product_id_uk UNIQUE (user_id, product_id)
);

CREATE TABLE review_report(
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES review (id) ON UPDATE CASCADE ON DELETE CASCADE,
    motive TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

----BEGIN INDEXES----

CREATE INDEX orderedAt_purchase ON purchase USING btree (orderedAt);

CREATE INDEX product_review ON review USING hash (product_id);

CREATE INDEX purchase_user_id ON purchase USING hash (user_id);

CREATE INDEX shopping_cart_user_id ON shopping_cart USING hash (user_id);

CREATE INDEX wishlist_user_id ON wishlist USING hash (user_id);

CREATE INDEX price_product ON product USING btree (price);

---- END INDEXES ----

---- BEGIN FTS INDEXES ----



ALTER TABLE product
ADD COLUMN tsvectors TSVECTOR;       

CREATE OR REPLACE FUNCTION product_FTS_update() RETURNS TRIGGER AS $$
BEGIN
 IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = (
         setweight(to_tsvector('english', NEW.name), 'A') ||
         setweight(to_tsvector('english', NEW.author), 'B')||
         setweight(to_tsvector('english', NEW.editor), 'C')||
         setweight(to_tsvector('english', NEW.synopsis), 'D')
        );
 END IF;
 IF TG_OP = 'UPDATE' THEN
         IF (NEW.name <> OLD.name OR NEW.author <> OLD.author OR NEW.editor <> OLD.editor OR NEW.synopsis <> OLD.synopsis) THEN
           NEW.tsvectors = (
             setweight(to_tsvector('english', NEW.name), 'A') ||
             setweight(to_tsvector('english', NEW.author), 'B') ||
             setweight(to_tsvector('english', NEW.editor), 'C')||
             setweight(to_tsvector('english', NEW.synopsis), 'D')
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

---- END FTS INDEXES ----

---- BEGIN MANAGE DELETED ACCOUNT TRIGGER (TRIGGER01) ----

CREATE OR REPLACE FUNCTION manage_deleted_account() RETURNS TRIGGER AS
$BODY$
BEGIN
        UPDATE users
        SET name = 'Deleted Account', profile_picture = 'df_user_img.png'
    
        WHERE users.id = OLD.user_id;
        RETURN OLD;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER manage_deleted_account_trigger
        BEFORE DELETE ON authenticated
        FOR EACH ROW
        EXECUTE PROCEDURE manage_deleted_account();

---- END MANAGE DELETED ACCOUNT TRIGGER ----

---- BEGIN MANAGE PURCHASE INSERT TRIGGER (TRIGGER02) ----

CREATE OR REPLACE FUNCTION manage_purchase_insert() RETURNS TRIGGER AS
$BODY$
DECLARE
    productID INTEGER;
    price INTEGER;
    discount INTEGER;
    shopping_cart_id INTEGER;

BEGIN
    BEGIN
        FOR productID IN EXECUTE 'SELECT product_id FROM shopping_cart WHERE user_id = $1' USING NEW.user_id
        LOOP
            EXECUTE 'SELECT price, discount FROM product WHERE id = $1' INTO price, discount USING productID;
            
            price := price-discount;
    
            EXECUTE 'INSERT INTO purchase_product (purchase_id, product_id, price) VALUES ($1, $2, $3)' USING NEW.id, productID, price;

        END LOOP;
        EXECUTE 'DELETE FROM shopping_cart WHERE user_id = $1' USING NEW.user_id;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when making a purchase';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER manage_purchase_insert_trigger
        AFTER INSERT ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE manage_purchase_insert();

---- END MANAGE PURCHASE INSERT TRIGGER  ----

---- BEGIN MANAGE INITIATE PRODUCT STATISTICS TRIGGER (TRIGGER03) ----

CREATE OR REPLACE FUNCTION initiate_product_statistics() RETURNS TRIGGER AS
$BODY$
DECLARE
    statistic_type TEXT;

BEGIN
    BEGIN
        FOR statistic_type IN EXECUTE 'SELECT statistic_type FROM statistic'
        LOOP
            EXECUTE 'INSERT INTO product_statistic (product_id, statistic_type, result) VALUES ($1, $2, DEFAULT)' USING NEW.id, statistic_type;
        END LOOP;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when initiating a product statistic';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER initiate_product_statistics_trigger
        AFTER INSERT ON product
        FOR EACH ROW
        EXECUTE PROCEDURE initiate_product_statistics();

---- END MANAGE INITIATE PRODUCT STATISTICS TRIGGER ----

---- BEGIN PAYMENT SUCCESSFULL NOTIFICATION TRIGGER (TRIGGER04) ----

CREATE OR REPLACE FUNCTION payment_successfull_notification() RETURNS TRIGGER AS
$BODY$
BEGIN
    BEGIN
        EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, date, isNew) VALUES ($1, $2, DEFAULT, DEFAULT)' USING NEW.user_id, 'payment_notification';
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when sending payment successfull notification';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER payment_successfull_notification_trigger
        AFTER INSERT ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE payment_successfull_notification();

---- END PAYMENT SUCCESSFULL NOTIFICATION TRIGGER----

---- BEGIN INSTOCK NOTIFICATION TRIGGER (TRIGGER05) ----

CREATE OR REPLACE FUNCTION instock_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    user_id INTEGER;

BEGIN
    BEGIN
        IF OLD.stock = 0 AND NEW.stock != OLD.stock THEN
            FOR user_id IN EXECUTE 'SELECT user_id FROM wishlist WHERE product_id = $1 GROUP BY user_id' USING NEW.id
            LOOP
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, date, isNew) VALUES ($1, $2, DEFAULT, DEFAULT)' USING user_id, 'instock_notification';
            END LOOP;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when sending in stock notification';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER instock_notification_trigger
        AFTER UPDATE ON product
        FOR EACH ROW
        EXECUTE PROCEDURE instock_notification();

---- END INSTOCK NOTIFICATION TRIGGER ----

---- BEGIN PURCHASE INFO NOTIFICATION TRIGGER (TRIGGER06) ----

CREATE OR REPLACE FUNCTION purchaseinfo_notification() RETURNS TRIGGER AS
$BODY$
BEGIN
    BEGIN
        IF NEW.isTracked = TRUE THEN
            IF NEW.isTracked != OLD.isTracked THEN
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, date, isNew) VALUES ($1, $2, DEFAULT, DEFAULT)' USING NEW.user_id, 'purchaseinfo_notification';
            END IF;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when sending purchase info notification';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER purchaseinfo_notification_trigger
        AFTER UPDATE ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE purchaseinfo_notification();

---- END PURCHASE INFO NOTIFICATION TRIGGER ----

---- BEGIN PRICE CHANGE NOTIFICATION TRIGGER (TRIGGER07) ----

CREATE OR REPLACE FUNCTION pricechange_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    user_id INTEGER;

BEGIN
    BEGIN
        IF NEW.price - NEW.discount != OLD.price - OLD.discount THEN
            FOR user_id IN EXECUTE 'SELECT user_id FROM shopping_cart WHERE product_id = $1 GROUP BY user_id' USING NEW.id
            LOOP
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, date, isNew) VALUES ($1, $2, DEFAULT, DEFAULT)' USING user_id, 'pricechange_notification';
            END LOOP;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when sending price change notification';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER pricechange_notification_trigger
        AFTER UPDATE ON product
        FOR EACH ROW
        EXECUTE PROCEDURE pricechange_notification();

---- END PRICE CHANGE NOTIFICATION TRIGGER ----

---- BEGIN REFUND PURCHASE TRIGGER (TRIGGER08) ----

CREATE OR REPLACE FUNCTION refund_purchase() RETURNS TRIGGER AS
$BODY$
DECLARE
    product_id INTEGER;
BEGIN
    BEGIN
        UPDATE wallet SET money = money + OLD.price WHERE wallet.user_id = OLD.user_id;
        FOR product_id IN EXECUTE 'SELECT product_id FROM purchase_product WHERE purchase_id = $1' USING OLD.id
        LOOP
            UPDATE product
            SET stock = stock + 1
            WHERE id = product_id;
        END LOOP;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when refunding purchase';
    END;
    RETURN OLD;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER refund_purchase_trigger
        BEFORE DELETE ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE refund_purchase();

---- END REFUND PURCHASE TRIGGER ----

---- BEGIN INSERT WALLET TRIGGER (TRIGGER09) ----

CREATE OR REPLACE FUNCTION insert_wallet() RETURNS TRIGGER AS
$BODY$
DECLARE
    currency_type TEXT;
BEGIN
    BEGIN
        EXECUTE 'SELECT currency_type FROM currency LIMIT 1' INTO currency_type;
        IF currency_type IS NOT NULL THEN
            EXECUTE 'INSERT INTO wallet (user_id, money, currency_type, transaction_date) VALUES ($1, DEFAULT, $2, NULL)' USING NEW.user_id, currency_type;
        END IF;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when adding a wallet to a user';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER insert_wallet_trigger
        AFTER INSERT ON authenticated
        FOR EACH ROW
        EXECUTE PROCEDURE insert_wallet();

---- END INSERT WALLET TRIGGER ----



