DROP SCHEMA IF EXISTS lbaw2315 CASCADE;

CREATE SCHEMA lbaw2315;

SET search_path TO lbaw2315;




-- TABLES

CREATE TABLE notification(
    notification_type TEXT PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE currency(
    currency_type TEXT PRIMARY KEY,
    currency_symbol TEXT NOT NULL DEFAULT '€'
);

CREATE TABLE payment(
    payment_type TEXT PRIMARY KEY
);

CREATE TABLE stage(
    stage_state TEXT PRIMARY KEY,
    stage_order INTEGER NOT NULL
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
    country TEXT DEFAULT 'Portugal' NOT NULL,
    profile_picture TEXT DEFAULT 'default.png' NOT NULL,
    remember_token VARCHAR(100)
);

CREATE TABLE password_reset_tokens (
    email VARCHAR(255) PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NULL
);


CREATE TABLE admin(
    admin_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE
);

CREATE TABLE authenticated(
    user_id INTEGER PRIMARY KEY REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    name TEXT,
    city TEXT,
    phone_number INT,
    postal_code TEXT,
    address TEXT,
    isBlocked BOOLEAN DEFAULT FALSE NOT NULL,
    payment_method TEXT REFERENCES payment (payment_type) ON UPDATE CASCADE ON DELETE SET NULL
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
    target_id INTEGER, 
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
    image TEXT DEFAULT 'default.png' NOT NULL
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
    stage_state TEXT NOT NULL DEFAULT 'start' REFERENCES stage (stage_state) ON UPDATE CASCADE ON DELETE CASCADE,
    isTracked BOOLEAN DEFAULT FALSE NOT NULL,
    orderedAt TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    orderArrivedAt TIMESTAMP WITH TIME ZONE NOT NULL CONSTRAINT order_ck CHECK (orderArrivedAt > orderedAt),
    refundedAt TIMESTAMP WITH TIME ZONE CONSTRAINT refund_ck CHECK ((refundedAt IS NULL) OR (orderArrivedAt < refundedAt))
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
        SET name = 'Deleted Account', profile_picture = 'default.png'
    
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
            
            price := price - price*discount/100;
    
            EXECUTE 'INSERT INTO purchase_product (purchase_id, product_id, price) VALUES ($1, $2, $3)' USING NEW.id, productID, price;

            UPDATE product SET stock = stock-1 WHERE product.id = productID;

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


---- BEGIN MANAGE UPDATE PURCHASE ORDER STATE TRIGGER (TRIGGER??) ----

CREATE OR REPLACE FUNCTION manage_purchase_stage_state_update() RETURNS TRIGGER AS
$BODY$
DECLARE
    stage_number INTEGER;
    next_stage TEXT;

BEGIN
    BEGIN
        IF NEW.stage_state = 'next' THEN
            EXECUTE 'SELECT stage_order FROM stage WHERE stage_state = $1' INTO stage_number USING OLD.stage_state;
            stage_number := stage_number + 1;
            EXECUTE 'SELECT stage_state FROM stage WHERE stage_order = $1' INTO next_stage USING stage_number;
            NEW.stage_state := next_stage;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Something wrong when updating order_stage';
    END;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER manage_purchase_stage_state_update_trigger
        BEFORE UPDATE ON purchase
        FOR EACH ROW
        EXECUTE PROCEDURE manage_purchase_stage_state_update();

---- END MANAGE PURCHASE STAGE STATE UPDATE TRIGGER  ----


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
        EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, 1, DEFAULT, DEFAULT)' USING NEW.user_id, 'Payment Notification';
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
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, $3, DEFAULT, DEFAULT)' USING user_id, 'In Stock Notification',NEW.id;
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

---- BEGIN OUT OF STOCK NOTIFICATION TRIGGER (TRIGGER06) ----
    
CREATE OR REPLACE FUNCTION nostock_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    user_id INTEGER;

BEGIN
    BEGIN
        IF OLD.stock != NEW.stock AND NEW.stock = 0 THEN
            FOR user_id IN EXECUTE 'SELECT user_id FROM shopping_cart WHERE product_id = $1 GROUP BY user_id' USING NEW.id
            LOOP
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, $3, DEFAULT, DEFAULT)' USING user_id, 'Out Of Stock Notification',NEW.id;
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

CREATE TRIGGER nostock_notification_trigger
    AFTER UPDATE ON product
    FOR EACH ROW
    EXECUTE PROCEDURE nostock_notification();

---- END INSTOCK NOTIFICATION TRIGGER ----

---- BEGIN PURCHASE INFO NOTIFICATION TRIGGER (TRIGGER07) ----

CREATE OR REPLACE FUNCTION purchaseinfo_notification() RETURNS TRIGGER AS
$BODY$
BEGIN
    BEGIN
        IF NEW.isTracked = TRUE THEN
            IF NEW.isTracked != OLD.isTracked THEN
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, 3, DEFAULT, DEFAULT)' USING NEW.user_id, 'Purchase Information Notification';
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

---- BEGIN PRICE CHANGE SHOPPING CART NOTIFICATION TRIGGER (TRIGGER08) ----

CREATE OR REPLACE FUNCTION pricechangeshoppingcart_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    user_id INTEGER;

BEGIN
    BEGIN
        IF NEW.price - (NEW.price*NEW.discount/100) != OLD.price - (OLD.price*OLD.discount/100) THEN
            FOR user_id IN EXECUTE 'SELECT user_id FROM shopping_cart WHERE product_id = $1 GROUP BY user_id' USING NEW.id
            LOOP
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, $3, DEFAULT, DEFAULT)' USING user_id, 'Price Change Shopping Cart Notification', NEW.id;
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

CREATE TRIGGER pricechangeshoppingcart_notification_trigger
        AFTER UPDATE ON product
        FOR EACH ROW
        EXECUTE PROCEDURE pricechangeshoppingcart_notification();

---- END PRICE CHANGE SHOPPING CART NOTIFICATION TRIGGER ----

---- BEGIN PRICE CHANGE WISHLIST NOTIFICATION TRIGGER (TRIGGER08) ----

CREATE OR REPLACE FUNCTION pricechangewishlist_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    user_id INTEGER;

BEGIN
    BEGIN
        IF NEW.price - (NEW.price*NEW.discount/100) != OLD.price - (OLD.price*OLD.discount/100) THEN
            FOR user_id IN EXECUTE 'SELECT user_id FROM wishlist WHERE product_id = $1 GROUP BY user_id' USING NEW.id
            LOOP
                EXECUTE 'INSERT INTO authenticated_notification (user_id, notification_type, target_id, date, isNew) VALUES ($1, $2, $3, DEFAULT, DEFAULT)' USING user_id, 'Price Change Wishlist Notification', NEW.id;
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

CREATE TRIGGER pricechangewishlist_notification_trigger
        AFTER UPDATE ON product
        FOR EACH ROW
        EXECUTE PROCEDURE pricechangewishlist_notification();

---- END PRICE CHANGE WISHLIST NOTIFICATION TRIGGER ----

---- BEGIN REFUND PURCHASE TRIGGER (TRIGGER089) ----

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

---- BEGIN INSERT WALLET TRIGGER (TRIGGER10) ----

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



INSERT INTO notification VALUES('Payment Notification','Your payment has been successful');
INSERT INTO notification VALUES('Purchase Information Notification','Thank you for purchasing at our store, this is your purchase information:');

--- FALTAM TRIGGERS ---
INSERT INTO notification VALUES('Changed Tracked Order','Your Tracked Order has been updated');
INSERT INTO notification VALUES('Refunded or Canceled Order','Your Order has been refunded or canceled');
--- FALTAM TRIGGERS ---

INSERT INTO notification VALUES('In Stock Notification','An item on your wishlist is currently in stock');
INSERT INTO notification VALUES('Out Of Stock Notification','An item on your shopping cart is currently out of stock');
INSERT INTO notification VALUES('Price Change Wishlist Notification','An item on your Wishlist has had its price changed');
INSERT INTO notification VALUES('Price Change Shopping Cart Notification','An item on your Shopping Cart has had its info changed');

INSERT INTO currency VALUES('euro');
INSERT INTO currency VALUES('pound');
INSERT INTO currency VALUES('dollar');
INSERT INTO currency VALUES('rupee');
INSERT INTO currency VALUES('yen');


INSERT INTO payment VALUES('store money');
INSERT INTO payment VALUES('paypal');
INSERT INTO payment VALUES('credit/debit card');

INSERT INTO stage VALUES('start', 0);
INSERT INTO stage VALUES('payment', 1);
INSERT INTO stage VALUES('order', 2);
INSERT INTO stage VALUES('transportation', 3);
INSERT INTO stage VALUES('delivered', 4);

INSERT INTO statistic VALUES('sales');
INSERT INTO statistic VALUES('revenue');
INSERT INTO statistic VALUES('AOV');
INSERT INTO statistic VALUES('returnrate');

INSERT INTO category VALUES('fiction');
INSERT INTO category VALUES('non-fiction');
INSERT INTO category VALUES('mystery');
INSERT INTO category VALUES('romance');
INSERT INTO category VALUES('comics');
INSERT INTO category VALUES('horror');
INSERT INTO category VALUES('dystopian');
INSERT INTO category VALUES('adventure');
INSERT INTO category VALUES('drama');
INSERT INTO category VALUES('fantasy');
INSERT INTO category VALUES('classic');
INSERT INTO category VALUES('satire');
INSERT INTO category VALUES('self-help');
INSERT INTO category VALUES('historical fiction');
INSERT INTO category VALUES('epic');
INSERT INTO category VALUES('children''s literature');
INSERT INTO category VALUES('science fiction');
INSERT INTO category VALUES('memoir');

INSERT INTO users(name,password,email) VALUES('Hazel Ezekiel','$2y$10$s3v9UMMlt7or9VV.MRKyI.bk8wQrtBcwgs8SAx3lgQEDvKRK0WG96','YTwwRXNS@outlook.com');
INSERT INTO users(name,password,email) VALUES('Emily Hudson','dJ*C^1r7<..l','RcctvSiO@gmail.com');
INSERT INTO users(name,password,email) VALUES('Jackson Elena','/b/&_i-TgZ\c','gtHPMWuc@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Josiah Leo','b+@.+@$ynt_K','MNbeWlZd@yahoo.com');
INSERT INTO users(name,password,email) VALUES('William Riley','i/%%o1BJvl;a','bgXhmcIV@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Noah David','5kiBs5hlzCW\','wPCrgYJw@outlook.com');
INSERT INTO users(name,password,email) VALUES('Miles Maverick','TWp>_uTaM%by','bXIjyQUo@outlook.com');
INSERT INTO users(name,password,email) VALUES('Sophia Carter','Td\!9$/Ar_KO','ufoAucfu@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Grayson David','eEYN,+kmi*oE','BIWiBIUk@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Naomi Isaiah','G=SsDKn!TCko','lcagcjJa@outlook.com');
INSERT INTO users(name,password,email) VALUES('Lucas Wyatt','0i9TBrk=\:7z','NekFCliW@gmail.com');
INSERT INTO users(name,password,email) VALUES('Violet Nora','Kba,oE37y`3e','ZpfQCkLc@gmail.com');
INSERT INTO users(name,password,email) VALUES('Ethan Lily','IH<F~Dp4e~=d','LzEkQUKp@gmail.com');
INSERT INTO users(name,password,email) VALUES('Sofia Mila','Z9m7.wuBX?>.','pkrliQTL@outlook.com');
INSERT INTO users(name,password,email) VALUES('Eleanor Kai','\n@bRVnJs#?E','ZvapfWNv@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Muhammad Emilia','Su-4p4,yV>>d','MpdMshOn@gmail.com');
INSERT INTO users(name,password,email) VALUES('Matthew Daniel','TUmV._!_/*:4','VhpejmTn@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Ella Ethan','0vca\LB7#3M,','tHjXUQpF@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Olivia Harper','lfhfZ;E2F@m,','YllgOVui@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Emilia Emilia','Q1rQb-uEZToF','QUEVNgjS@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Ella Riley','^f7bW~M.5?|#','QkdQvWjN@gmail.com');
INSERT INTO users(name,password,email) VALUES('Naomi Camila','lX`gp0&4o<2=','KzhuCbGW@outlook.com');
INSERT INTO users(name,password,email) VALUES('Maya Isabella','R;Ouyas6b0Cp','rKwuCSXQ@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Luke Noah','3E.<l_L2xe_1','aAZIqDqU@gmail.com');
INSERT INTO users(name,password,email) VALUES('Scarlett Chloe','^tNY#ETo:yx*','gAkKkSbq@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Isaiah Delilah','0W1>35qw2TXm','ETiafnav@yahoo.com');
INSERT INTO users(name,password,email) VALUES('James Benjamin','|1Lft2gseb,g','oQZgepBo@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Isla Emilia',';^u132oJU:\c','uvkaZLBQ@outlook.com');
INSERT INTO users(name,password,email) VALUES('Abigail Layla','/\8r-TT6>zX@','kBulrEES@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Theo Gabriel','v~m*k!4Ri;EN','ATqPXPlA@outlook.com');
INSERT INTO users(name,password,email) VALUES('Sebastian Sebastian','mSr;b6=6b>AQ','nVprTgQp@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Charlotte Emily',',$Ka9^X~@a|D','SjIsXyjg@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Luke Oliver',';S;NJtWNTl/r','tevswKWk@gmail.com');
INSERT INTO users(name,password,email) VALUES('Miles Hazel','$$Gf/D7HUmpO','ZCmrrqNX@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Aurora Jayden','~tt4O.~-do-l','ddnjtZkS@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Maya Wyatt','s^?gdNMLb**a','zdbRzLqe@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Zoe Madison','rV4a;yE1^N?E','xxLHzmoQ@outlook.com');
INSERT INTO users(name,password,email) VALUES('Paisley Willow','<n3gt29|tT<=','zBmajLLn@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Sebastian Kai','x_<Q8U*8c`gy','JeVGxCks@gmail.com');
INSERT INTO users(name,password,email) VALUES('David Jacob','A_o*|%Cilo2`','aruDWzcx@outlook.com');
INSERT INTO users(name,password,email) VALUES('Olivia James','RJYNsTKb#!G:','XOrNBJsG@gmail.com');
INSERT INTO users(name,password,email) VALUES('Hazel Daniel','ZpGsPnx:r2E0','dtSGODzQ@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Gabriel Amelia','AG/Rk>1Cgm.g','mKIWSqaC@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Nova Jackson','Bib#P>F=RlI`','ffwHJNib@outlook.com');
INSERT INTO users(name,password,email) VALUES('Aria Gianna','&wQCZ7VG|#.A','hSjPkHVB@gmail.com');
INSERT INTO users(name,password,email) VALUES('Ivy Aurora','Z.m3@4d7E:Fa','MfAGxXQd@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Noah Ezra','-;;|cJ*VzLnq','WmEOtfTu@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Benjamin James','R|KoTLS4LaaZ','YAaFCPCw@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Nova Henry','\a#-|hY+j2zg','JfYQOhVX@outlook.com');
INSERT INTO users(name,password,email) VALUES('Muhammad Logan','DFrxFSJfEHnp','wODLXLRW@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Harper Lily','?Rq%45JyN8Wv','JkqISNVr@gmail.com');
INSERT INTO users(name,password,email) VALUES('Grace Alexander',',ol+C/|/dw0v','zISjrFCe@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Ezra Mia','->3*<-OU/jMo','SAMIbqlU@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Ezekiel Nora','r&ia.e/4s%Ui','gxSDxxwj@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Amelia Grace','eytn\.j/hn|3','oomdCdEI@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Mila Ava','S-H0^66>`,vg','RdGRXwhV@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Santiago Zoey','/vu.Ci\mHe?A','HsZXbVUi@gmail.com');
INSERT INTO users(name,password,email) VALUES('Elias Aria','6s9AfNz5MGP7','CoOhlyql@gmail.com');
INSERT INTO users(name,password,email) VALUES('Paisley Jayden','/q1|KeYs$jGy','qiepAgaZ@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Theo Scarlett',';l0TO#\/oHwi','gqiVARhZ@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Waylon Lily','Zd+kKalQZ\_U','EDAtALxp@gmail.com');
INSERT INTO users(name,password,email) VALUES('Kai Lucas','7O!`>9kduFq_','QEMMhaoT@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Naomi Emilia','=wTJ*r~SVJ^M','sFCmReXu@outlook.com');
INSERT INTO users(name,password,email) VALUES('Zoe James','Bz8lenpqKq;.','xySbaHjL@outlook.com');
INSERT INTO users(name,password,email) VALUES('Jacob Noah','pA%5COw?z1:T','YwprdcPY@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Aurora Owen',',5$hNp5M6ggJ','DaEkBhZT@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Ezra Hazel','>p_--rpJTqb,','wsgmhqZS@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Henry Leo','F=LIxQM%^N0B','OIqZJcLx@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Gianna Isabella','Y1mXcgj.N6\+','UTAOSgWY@gmail.com');
INSERT INTO users(name,password,email) VALUES('Noah Elias','mDMC@3r5ua>2','ZtwXcBKl@gmail.com');
INSERT INTO users(name,password,email) VALUES('Grace Evelyn','H8d$P1;<aJ~.','lDBAOprT@outlook.com');
INSERT INTO users(name,password,email) VALUES('Jacob Harper','3a=iAdq%N`JR','IfYljJcL@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Zoey Abigail','`8~rblc@q&%I','aPYssGMU@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Harper Kai','hx,@`<x@r$Nx','qNZtAtsw@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Asher Aria','RW6&9QdUYn5@','qTeuGrmL@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Emily Jacob','@M|v~y|uAHkt','VLYbjwyV@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Grayson Elena','UuWO/N\?B`\d','IdQEprsF@gmail.com');
INSERT INTO users(name,password,email) VALUES('Mia Mason','j4R#v@M4PoxB','qFwlhqra@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Julian Olivia','2XO9u0PPQ>X,','iuOOZoFh@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Noah Luna','HCss\^9kFlJF','nbHyKhSR@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Hudson Liam','CF63?r\FTTR:','dlRPzqGk@outlook.com');
INSERT INTO users(name,password,email) VALUES('Zoe Athena','M>;!v,~QLlT9','jjoKTgLV@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Elias Jacob','jT7XOM4:m5=j','iKsMjruK@gmail.com');
INSERT INTO users(name,password,email) VALUES('Avery Layla',';g=5.1~`uT\/','IleZflCZ@gmail.com');
INSERT INTO users(name,password,email) VALUES('Daniel Leilani','P0$~:cI/Y5gU','YElLVbbq@outlook.com');
INSERT INTO users(name,password,email) VALUES('Leilani Kai','UZ+q<GM*mH3O','qXFShmNm@gmail.com');
INSERT INTO users(name,password,email) VALUES('Mateo Grayson','WfvIr3Zb>$A~','lDoTPKXZ@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Noah Elena','xxZ;4>G$DRZC','kuhnTLsr@outlook.com');
INSERT INTO users(name,password,email) VALUES('Hazel William','rYp7JG.#;/MI','bOpudXtN@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Eleanor Delilah','S9@/t8&v<;wQ','vCoLZpYh@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Emilia Leo','*3/ZR1Z5>tD?','lZQlParw@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Theodore Ava','==S:tPkA*p*.','bApoafyy@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Jayden Avery','QrR$C1~~$PP^','GeGfRDZQ@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Matthew Delilah','#uGQ8#?X7&Oh','NPiaFAyU@outlook.com');
INSERT INTO users(name,password,email) VALUES('Michael Olivia','tuM.8G_J!E7D','fybBmLBd@yahoo.com');
INSERT INTO users(name,password,email) VALUES('Mason Liam','@Vm|s@a<yn.M','twffnhOV@hotmail.com');
INSERT INTO users(name,password,email) VALUES('Aurora Daniel',';V^XV@r&H-|C','NfKqFhEY@gmail.com');
INSERT INTO users(name,password,email) VALUES('William Sophia','2%6mXADEtbiL','TaXuOgsd@gmail.com');
INSERT INTO users(name,password,email) VALUES('Gabriel Ellie','.fZ3pbX$eeX_','sasfxBno@gmail.com');
INSERT INTO users(name,password,email) VALUES('Sofia Lily','C6wz$%2|qLzS','XZuvPZud@yahoo.com');

INSERT INTO admin VALUES(1);
INSERT INTO admin VALUES(2);
INSERT INTO admin VALUES(3);
INSERT INTO admin VALUES(4);

INSERT INTO authenticated(user_id,address,isBlocked) VALUES(5,'Viseu, Sesimbra, Rua da Solidariedade, 5458-130','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(6,'Viana do Castelo, P�voa de Varzim, Avenida das Margaridas, 7795-641','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(7,'Porto, P�voa de Varzim, Rua do Carmo, 6650-350','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(8,'Viana do Castelo, Odivelas, Pra�a da Justi�a, 2517-431','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(9,'Porto, Castelo de Vide, Rua da Toler�ncia, 2018-175','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(10,'Set�bal, Almada, Rua do Cabo, 866-394','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(11,'Faro, Matosinhos, Rua dos P�ssaros, 995-218','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(12,'Set�bal, Albufeira, Avenida dos Pl�tanos, 7522-740','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(13,'Braga, Set�bal, Rua das Rosas, 6562-323','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(14,'Aveiro, Set�bal, Rua da Gl�ria, 2481-669','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(15,'Viseu, Covilh�, Avenida dos Aliados, 8038-718','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(16,'Castelo Branco, Figueira da Foz, Rua da Amizade, 6549-193','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(17,'Viana do Castelo, Portim�o, Rua da Solidariedade, 2542-811','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(18,'Portalegre, Barreiro, Avenida das Flores, 2481-393','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(19,'Viseu, Estoril, Rua de Santo Ant�nio, 5710-570','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(20,'Aveiro, Matosinhos, Rua da Saudade, 8445-217','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(21,'Coimbra, Loures, Pra�a da Alegria, 5629-329','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(22,'Faro, Vila do Conde, Rua da Montanha, 5681-380','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(23,'Braga, Barreiro, Rua dos Mios�tis, 2340-334','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(24,'Coimbra, Matosinhos, Rua das Glic�nias, 8596-359','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(25,'Viana do Castelo, Barreiro, Pra�a dos Her�is, 3094-877','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(26,'Aveiro, Santo Tirso, Rua do Laranjal, 6178-742','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(27,'Viseu, Covilh�, Rua dos Mios�tis, 7368-513','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(28,'Lisboa, Amadora, Rua do Sol, 1425-225','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(29,'Bragan�a, Esposende, Rua do Ouro, 7899-690','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(30,'Coimbra, Caldas da Rainha, Rua dos Jardins, 752-459','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(31,'Lisboa, P�voa de Varzim, Avenida dos Pl�tanos, 8205-920','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(32,'Viana do Castelo, Loul�, Rua dos Lilases, 7448-998','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(33,'Castelo Branco, Maia, Pra�a do Marqu�s, 8062-447','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(34,'Castelo Branco, Oeiras, Avenida das Orqu�deas, 821-990','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(35,'Guarda, Portim�o, Rua dos Pinheiros, 2671-235','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(36,'Faro, Castelo de Vide, Avenida das Violetas, 766-211','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(37,'Set�bal, Figueira da Foz, Rua das Az�leas, 8273-415','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(38,'Viana do Castelo, Penafiel, Largo das Oliveiras, 4755-229','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(39,'Aveiro, Oeiras, Rua dos Choupos, 4745-892','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(40,'Guarda, Elvas, Avenida da Boa Esperan�a, 3668-465','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(41,'Faro, Fafe, Rua das Margaridas, 8530-820','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(42,'Set�bal, Trofa, Pra�a dos Jacarand�s, 9729-824','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(43,'Faro, Trofa, Rua do Laranjal, 215-260','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(44,'Guarda, Vila do Conde, Rua dos Ger�nios, 4552-447','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(45,'Bragan�a, Caldas da Rainha, Rua da Alfazema, 2875-354','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(46,'Beja, Oeiras, Rua do Laranjal, 2363-771','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(47,'Castelo Branco, Bragan�a, Rua da Madressilva, 5918-294','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(48,'Set�bal, Elvas, Avenida dos Jacarand�s, 4964-745','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(49,'Portalegre, Matosinhos, Rua de S�o Jo�o, 4211-894','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(50,'Castelo Branco, Esmoriz, Rua da Cova, 7439-698','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(51,'Braga, Albufeira, Avenida das Orqu�deas, 9937-584','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(52,'Coimbra, Santa Maria da Feira, Rua da Serra, 2009-726','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(53,'Beja, Castelo de Vide, Rua da Saudade, 1375-929','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(54,'Bragan�a, S�o Jo�o da Madeira, Largo do Mercado, 8026-418','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(55,'Leiria, S�o Jo�o da Madeira, Pra�a da Rep�blica, 5458-446','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(56,'Set�bal, Odivelas, Rua do Castelo, 6720-761','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(57,'Viana do Castelo, Lagos, Rua dos Pinheiros, 2132-782','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(58,'Vila Real, Trofa, Avenida dos Jardins, 4085-734','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(59,'Viseu, Portim�o, Rua da Alameda, 2542-431','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(60,'�vora, Vila Nova de Gaia, Rua dos Choupos, 3854-243','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(61,'Viseu, Elvas, Rua da Alegria, 3765-632','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(62,'Viana do Castelo, Beira-Mar, Rua da Toler�ncia, 848-546','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(63,'Viana do Castelo, Odivelas, Rua dos Castanheiros, 1936-294','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(64,'Porto, Maia, Pra�a da Flores, 2938-634','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(65,'Lisboa, Amadora, Rua dos Pinheiros, 2549-353','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(66,'Set�bal, Amarante, Rua da Harmonia, 9906-741','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(67,'Braga, Castelo Branco, Rua da Carvalheira, 1483-241','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(68,'Castelo Branco, Lagos, Rua da Fonte, 7249-926','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(69,'Castelo Branco, Vila do Conde, Rua dos Cravos, 4475-636','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(70,'�vora, Caldas da Rainha, Rua dos Girass�is, 6666-684','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(71,'Beja, Almada, Rua das Magn�lias, 3691-305','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(72,'Beja, Lamego, Rua da Aldeia, 8605-622','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(73,'Santar�m, Estoril, Avenida da Esta��o, 2166-749','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(74,'Aveiro, Bragan�a, Rua das Orqu�deas, 7866-866','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(75,'Beja, Lagos, Rua do Bem-estar, 2080-678','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(76,'Porto, Estoril, Pra�a das Cam�lias, 3129-692','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(77,'Viana do Castelo, Vila Real de Santo Ant�nio, Largo dos Castanheiros, 6478-134','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(78,'Portalegre, Penafiel, Rua dos Pinheiros, 1287-861','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(79,'Vila Real, Chaves, Rua dos Louros, 2525-503','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(80,'Coimbra, Santa Maria da Feira, Avenida da Sustentabilidade, 2228-721','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(81,'Bragan�a, Loul�, Rua da Alameda, 2843-632','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(82,'Set�bal, Caldas da Rainha, Rua da Cidadania, 5842-190','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(83,'Bragan�a, Caldas da Rainha, Rua da Boavista, 8723-638','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(84,'Santar�m, Sesimbra, Pra�a das Oliveiras, 2013-307','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(85,'Vila Real, Castelo Branco, Avenida das Flores, 835-448','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(86,'Lisboa, Loul�, Pra�a da Diversidade, 503-125','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(87,'Castelo Branco, Amadora, Rua da Igualdade, 430-767','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(88,'Leiria, P�voa de Varzim, Rua da Alfazema, 4471-969','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(89,'Guarda, Set�bal, Rua da M�sica, 9640-890','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(90,'Vila Real, Amadora, Largo dos Narcisos, 9339-717','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(91,'Lisboa, Ponte de Lima, Rua de Santa Catarina, 7358-198','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(92,'Bragan�a, Vila Franca de Xira, Rua das Papoilas, 4169-630','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(93,'Faro, Vila Real, Rua dos Pescadores, 9357-116','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(94,'Beja, Gondomar, Rua da Ecologia, 9303-631','FALSE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(95,'�vora, Penafiel, Avenida Dom Jo�o II, 5068-790','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(96,'Lisboa, Rio Maior, Pra�a de Cam�es, 5133-798','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(97,'Viana do Castelo, Santa Maria da Feira, Largo da Miseric�rdia, 3157-605','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(98,'�vora, Santo Tirso, Avenida da Esta��o, 6439-761','TRUE');
INSERT INTO authenticated(user_id,address,isBlocked) VALUES(99,'Set�bal, Odivelas, Rua do Porto, 6043-797','TRUE');

-- Realistic Books
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language,image) VALUES('The Great Gatsby', 'A 1925 novel by American writer F. Scott Fitzgerald. Set in the Jazz Age on Long Island, the novel depicts narrator Nick Carraway''s interactions with mysterious millionaire Jay Gatsby.', 180, 0, 10, 'F. Scott Fitzgerald', 'Charles Scribner''s Sons', 'English', 'the_great_gatsby.png');
INSERT INTO product_category(product_id,category_type) VALUES(1,'non-fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('To Kill a Mockingbird', 'A novel by Harper Lee. It explores the irrationality of adult attitudes toward race and class in the Deep South of the 1930s.', 200, 0, 15, 'Harper Lee', 'J.B. Lippincott & Co.', 'English', 'to_kill_a_mockingbird.png');
INSERT INTO product_category(product_id, category_type) VALUES(2, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('1984', 'A dystopian novel by George Orwell. It is set in a superstate known as Oceania, where the ruling party seeks to control thought and suppress personal freedom.', 220, 0, 20, 'George Orwell', 'Secker & Warburg', 'English', '1984.png');
INSERT INTO product_category(product_id, category_type) VALUES(3, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Pride and Prejudice', 'A romantic novel by Jane Austen. It follows the emotional development of Elizabeth Bennet, who learns the error of making hasty judgments and comes to appreciate the difference between the superficial and the essential.', 180, 0, 18, 'Jane Austen', 'T. Egerton, Whitehall', 'English', 'pride_and_prejudice.png');
INSERT INTO product_category(product_id, category_type) VALUES(4, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Hobbit', 'A fantasy novel by J.R.R. Tolkien. It follows the journey of Bilbo Baggins as he sets out on a quest to reclaim a treasure guarded by a dragon.', 250, 0, 12, 'J.R.R. Tolkien', 'George Allen & Unwin', 'English', 'the_hobbit.png');
INSERT INTO product_category(product_id, category_type) VALUES(5, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Catcher in the Rye', 'A novel by J.D. Salinger. It is known for its themes of teenage angst and alienation. The protagonist, Holden Caulfield, experiences a series of events in New York City.', 190, 0, 15, 'J.D. Salinger', 'Little, Brown and Company', 'English', 'the_catcher_in_the_rye.png');
INSERT INTO product_category(product_id, category_type) VALUES(6, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Da Vinci Code', 'A mystery thriller novel by Dan Brown. It follows symbologist Robert Langdon as he investigates a murder at the Louvre Museum in Paris.', 210, 0, 17, 'Dan Brown', 'Doubleday', 'English', 'the_da_vinci_code.png');
INSERT INTO product_category(product_id, category_type) VALUES(7, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Shining', 'A horror novel by Stephen King. It tells the story of Jack Torrance, an aspiring writer and recovering alcoholic who accepts a position as the off-season caretaker of the historic Overlook Hotel in the Colorado Rockies.', 230, 0, 14, 'Stephen King', 'Doubleday', 'English', 'the_shining.png');
INSERT INTO product_category(product_id, category_type) VALUES(8, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Hunger Games', 'A dystopian novel by Suzanne Collins. It is set in the dystopian nation of Panem, where each year, children from the 12 districts are selected to participate in a televised battle to the death.', 240, 0, 16, 'Suzanne Collins', 'Scholastic Corporation', 'English', 'the_hunger_games.png');
INSERT INTO product_category(product_id, category_type) VALUES(9, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Girl on the Train', 'A psychological thriller novel by Paula Hawkins. It follows an alcoholic woman who becomes involved in a missing person investigation.', 200, 0, 13, 'Paula Hawkins', 'Riverhead Books', 'English', 'the_girl_on_the_train.png');
INSERT INTO product_category(product_id, category_type) VALUES(10, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Lord of the Rings', 'A high fantasy novel by J.R.R. Tolkien. The story follows the hobbit Frodo Baggins as he sets out on a quest to destroy the One Ring and defeat the Dark Lord Sauron.', 260, 0, 10, 'J.R.R. Tolkien', 'George Allen & Unwin', 'English', 'the_lord_of_the_rings.png');
INSERT INTO product_category(product_id, category_type) VALUES(11, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Gone Girl', 'A psychological thriller novel by Gillian Flynn. It explores the disintegration of a marriage following the disappearance of a woman on her fifth wedding anniversary.', 210, 0, 15, 'Gillian Flynn', 'Crown Publishing Group', 'English', 'gone_girl.png');
INSERT INTO product_category(product_id, category_type) VALUES(12, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Great Expectations', 'A novel by Charles Dickens. It follows the life of an orphan named Pip, from his childhood through often painful experiences to adulthood.', 190, 0, 12, 'Charles Dickens', 'Chapman & Hall', 'English', 'great_expectations.png');
INSERT INTO product_category(product_id, category_type) VALUES(13, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Harry Potter and the Sorcerer''s Stone', 'A fantasy novel by J.K. Rowling. It follows the journey of a young wizard, Harry Potter, as he discovers his magical abilities and attends Hogwarts School of Witchcraft and Wizardry.', 250, 0, 14, 'J.K. Rowling', 'Bloomsbury', 'English', 'harry_potter_and_the_sorcerers_stone.png');
INSERT INTO product_category(product_id, category_type) VALUES(14, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Fault in Our Stars', 'A novel by John Green. It tells the story of two teenagers, Hazel Grace Lancaster and Augustus Waters, who are dealing with the challenges of living with cancer.', 200, 0, 20, 'John Green', 'Dutton Books', 'English', 'the_fault_in_our_stars.png');
INSERT INTO product_category(product_id, category_type) VALUES(15, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Maze Runner', 'A dystopian science fiction novel by James Dashner. It follows a group of young people who wake up in a mysterious maze with no memory of how they got there.', 220, 0, 18, 'James Dashner', 'Delacorte Press', 'Portuguese', 'the_maze_runner.png');
INSERT INTO product_category(product_id, category_type) VALUES(16, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Kite Runner', 'A novel by Khaled Hosseini. It tells the story of Amir, a young boy from Kabul, and his complex relationship with his friend Hassan.', 210, 0, 16, 'Khaled Hosseini', 'Riverhead Books', 'English', 'the_kite_runner.png');
INSERT INTO product_category(product_id, category_type) VALUES(17, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Girl with the Dragon Tattoo', 'A psychological thriller novel by Stieg Larsson. It follows journalist Mikael Blomkvist and hacker Lisbeth Salander as they investigate a wealthy family with dark secrets.', 230, 0, 14, 'Stieg Larsson', 'Norstedts Förlag', 'Swedish', 'the_girl_with_the_dragon_tattoo.png');
INSERT INTO product_category(product_id, category_type) VALUES(18, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Chronicles of Narnia', 'A series of seven fantasy novels by C.S. Lewis. The books follow the adventures of children who are magically transported to the world of Narnia.', 260, 0, 12, 'C.S. Lewis', 'Geoffrey Bles', 'English', 'the_chronicles_of_narnia.png');
INSERT INTO product_category(product_id, category_type) VALUES(19, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Road', 'A post-apocalyptic novel by Cormac McCarthy. It follows a father and son as they journey across a landscape devastated by an unspecified cataclysm.', 240, 0, 15, 'Cormac McCarthy', 'Alfred A. Knopf', 'English', 'the_road.png');
INSERT INTO product_category(product_id, category_type) VALUES(20, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Alchemist', 'A philosophical novel by Paulo Coelho. It follows the journey of Santiago, a young shepherd, as he sets out to discover his personal legend.', 190, 0, 17, 'Paulo Coelho', 'Rocco', 'Portuguese', 'the_alchemist.png');
INSERT INTO product_category(product_id, category_type) VALUES(21, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Dracula', 'A gothic horror novel by Bram Stoker. It tells the story of Dracula''s attempt to move from Transylvania to England to spread the undead curse, and his battle with a young lawyer named Jonathan Harker.', 220, 0, 20, 'Bram Stoker', 'Archibald Constable & Company', 'English', 'dracula.png');
INSERT INTO product_category(product_id, category_type) VALUES(22, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Outsiders', 'A coming-of-age novel by S.E. Hinton. It follows the lives of two rival groups, the Greasers and the Socs, and the conflicts they face.', 200, 0, 16, 'S.E. Hinton', 'Viking Press', 'English', 'the_outsiders.png');
INSERT INTO product_category(product_id, category_type) VALUES(23, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Stand', 'A post-apocalyptic horror novel by Stephen King. It explores the clash between forces of good and evil in a world ravaged by a deadly pandemic.', 250, 0, 14, 'Stephen King', 'Doubleday', 'English', 'the_stand.png');
INSERT INTO product_category(product_id, category_type) VALUES(24, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Picture of Dorian Gray', 'A philosophical novel by Oscar Wilde. It tells the story of a man whose portrait ages while he remains young and indulges in a hedonistic lifestyle.', 210, 0, 15, 'Oscar Wilde', 'Lippincott''s Monthly Magazine', 'English', 'the_picture_of_dorian_gray.png');
INSERT INTO product_category(product_id, category_type) VALUES(25, 'classic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Grapes of Wrath', 'A novel by John Steinbeck. It follows the Joad family as they travel westward during the Dust Bowl era of the 1930s.', 190, 0, 18, 'John Steinbeck', 'The Viking Press', 'English', 'the_grapes_of_wrath.png');
INSERT INTO product_category(product_id, category_type) VALUES(26, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Frankenstein', 'A gothic novel by Mary Shelley. It tells the story of Victor Frankenstein, a young scientist who creates a sapient creature in an unorthodox scientific experiment.', 220, 0, 20, 'Mary Shelley', 'Lackington, Hughes, Harding, Mavor, & Jones', 'English', 'frankenstein.png');
INSERT INTO product_category(product_id, category_type) VALUES(27, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Scarlet Letter', 'A novel by Nathaniel Hawthorne. It explores the consequences of sin and the nature of identity in the 17th-century Puritan society of Massachusetts.', 200, 0, 15, 'Nathaniel Hawthorne', 'Ticknor, Reed, and Fields', 'English', 'the_scarlet_letter.png');
INSERT INTO product_category(product_id, category_type) VALUES(28, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('One Hundred Years of Solitude', 'A novel by Gabriel Garcia Marquez. It tells the multi-generational story of the Buendía family in the fictional town of Macondo.', 240, 0, 14, 'Gabriel Garcia Marquez', 'Editorial Sudamericana', 'Spanish', 'one_hundred_years_of_solitude.png');
INSERT INTO product_category(product_id, category_type) VALUES(29, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Count of Monte Cristo', 'An adventure novel by Alexandre Dumas. It follows the story of Edmond Dantès, a sailor who is falsely accused of treason and seeks revenge against those who betrayed him.', 260, 0, 12, 'Alexandre Dumas', 'Le Journal des Débats', 'French', 'the_count_of_monte_cristo.png');
INSERT INTO product_category(product_id, category_type) VALUES(30, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Catch-22', 'A satirical novel by Joseph Heller. It follows the experiences of a U.S. Army Air Force B-25 bombardier during World War II.', 210, 0, 16, 'Joseph Heller', 'Simon & Schuster', 'English', 'catch_22.png');
INSERT INTO product_category(product_id, category_type) VALUES(31, 'satire');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Handmaid''s Tale', 'A dystopian novel by Margaret Atwood. It is set in the near future where a totalitarian regime has taken control and subjugated women.', 230, 0, 15, 'Margaret Atwood', 'McClelland & Stewart', 'English', 'the_handmaids_tale.png');
INSERT INTO product_category(product_id, category_type) VALUES(32, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Color Purple', 'A novel by Alice Walker. It tells the story of Celie, an African American woman, and her struggles in the early 20th century.', 190, 0, 18, 'Alice Walker', 'Harcourt Brace Jovanovich', 'English', 'the_color_purple.png');
INSERT INTO product_category(product_id, category_type) VALUES(33, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Moby-Dick', 'A novel by Herman Melville. It follows the obsessive quest of Ahab, the captain of the whaling ship Pequod, for revenge against the giant white sperm whale, Moby Dick.', 250, 0, 14, 'Herman Melville', 'Richard Bentley', 'English', 'moby_dick.png');
INSERT INTO product_category(product_id, category_type) VALUES(34, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Book Thief', 'A novel by Markus Zusak. It is narrated by Death and tells the story of a young girl named Liesel Meminger in Nazi Germany.', 200, 0, 16, 'Markus Zusak', 'Knopf', 'English', 'the_book_thief.png');
INSERT INTO product_category(product_id, category_type) VALUES(35, 'historical fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Wuthering Heights', 'A novel by Emily Brontë. It explores the destructive effects of passion and revenge in the lives of two Yorkshire families.', 220, 0, 20, 'Emily Brontë', 'Thomas Cautley Newby', 'English', 'wuthering_heights.png');
INSERT INTO product_category(product_id, category_type) VALUES(36, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Odyssey', 'An epic poem attributed to Homer. It tells the story of Odysseus and his long journey home after the fall of Troy.', 240, 0, 14, 'Homer', 'Various', 'Ancient Greek', 'the_odyssey.png');
INSERT INTO product_category(product_id, category_type) VALUES(37, 'epic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Road Less Traveled', 'A self-help book by M. Scott Peck. It explores the importance of discipline and personal growth for a fulfilling life.', 180, 0, 18, 'M. Scott Peck', 'Simon & Schuster', 'English', 'the_road_less_traveled.png');
INSERT INTO product_category(product_id, category_type) VALUES(38, 'self-help');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Brave New World', 'A dystopian novel by Aldous Huxley. It is set in a futuristic World State where citizens are conditioned for contentment and obedience.', 260, 0, 15, 'Aldous Huxley', 'Chatto & Windus', 'English', 'brave_new_world.png');
INSERT INTO product_category(product_id, category_type) VALUES(39, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Secret Garden', 'A novel by Frances Hodgson Burnett. It tells the story of Mary Lennox, a lonely and spoiled girl who discovers a hidden, magical garden.', 190, 0, 20, 'Frances Hodgson Burnett', 'Frederick A. Stokes', 'English', 'the_secret_garden.png');
INSERT INTO product_category(product_id, category_type) VALUES(40, 'children''s literature');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Jungle Book', 'A collection of stories by Rudyard Kipling. It follows the adventures of Mowgli, a boy raised by wolves in the Indian jungle.', 180, 0, 18, 'Rudyard Kipling', 'Macmillan Publishers', 'English', 'the_jungle_book.png');
INSERT INTO product_category(product_id, category_type) VALUES(41, 'children''s literature');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Sun Also Rises', 'A novel by Ernest Hemingway. It explores the experiences of the "Lost Generation" after World War I.', 200, 0, 20, 'Ernest Hemingway', 'Scribner', 'English', 'the_sun_also_rises.png');
INSERT INTO product_category(product_id, category_type) VALUES(42, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Secret Life of Bees', 'A novel by Sue Monk Kidd. It follows the journey of a young girl named Lily Owens as she searches for clues about her mother.', 220, 0, 15, 'Sue Monk Kidd', 'Viking Penguin', 'English', 'the_secret_life_of_bees.png');
INSERT INTO product_category(product_id, category_type) VALUES(43, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Road to Wigan Pier', 'A social and political report by George Orwell. It examines the bleak living conditions among the working-class in England during the 1930s.', 190, 0, 12, 'George Orwell', 'Gollancz', 'English', 'the_road_to_wigan_pier.png');
INSERT INTO product_category(product_id, category_type) VALUES(44, 'non-fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Metamorphosis', 'A novella by Franz Kafka. It tells the story of Gregor Samsa, who wakes up one morning to find himself transformed into a giant insect.', 180, 0, 18, 'Franz Kafka', 'Kurt Wolff Verlag', 'German', 'the_metamorphosis.png');
INSERT INTO product_category(product_id, category_type) VALUES(45, 'classic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Glass Castle', 'A memoir by Jeannette Walls. It recounts the unconventional, poverty-stricken upbringing Walls and her siblings had at the hands of their deeply dysfunctional parents.', 210, 0, 20, 'Jeannette Walls', 'Scribner', 'English', 'the_glass_castle.png');
INSERT INTO product_category(product_id, category_type) VALUES(46, 'memoir');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Brothers Karamazov', 'A novel by Fyodor Dostoevsky. It explores the themes of faith, morality, and the consequences of free will.', 240, 0, 15, 'Fyodor Dostoevsky', 'The Russian Messenger', 'Russian', 'the_brothers_karamazov.png');
INSERT INTO product_category(product_id, category_type) VALUES(47, 'classic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Hitchhiker''s Guide to the Galaxy', 'A science fiction comedy series by Douglas Adams. It follows the misadventures of an unwitting human and his alien friend as they travel through space.', 220, 0, 16, 'Douglas Adams', 'Pan Books', 'English', 'the_hitchhikers_guide_to_the_galaxy.png');
INSERT INTO product_category(product_id, category_type) VALUES(48, 'science fiction');


INSERT INTO purchase (user_id, price, quantity, payment_type, destination, stage_state, isTracked, orderedAt, orderArrivedAt, refundedAt) 
VALUES (60, 5000, 3, 'paypal', '123 Main St', 'start', TRUE, '2021-12-20T17:30:00Z', '2022-12-20T17:30:00Z', '2023-10-20T17:30:00Z');

INSERT INTO purchase (user_id, price, quantity, payment_type, destination, stage_state, isTracked, orderedAt, orderArrivedAt, refundedAt) 
VALUES (70, 200, 3, 'paypal', '123 Main St', 'start', FALSE, DEFAULT, '2025-01-02T14:30:00Z', null);
