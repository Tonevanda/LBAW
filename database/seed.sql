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
    orderedAt TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
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



INSERT INTO notification VALUES('payment_notification','Your payment has been successful');
INSERT INTO notification VALUES('instock_notification','An item on your wishlist is currently in stock');
INSERT INTO notification VALUES('purchaseinfo_notification','Thank you for purchasing at our store, this is your purchase information:');
INSERT INTO notification VALUES('pricechange_notification','An item on your wishlist has had its price changed');

INSERT INTO currency VALUES('euro');
INSERT INTO currency VALUES('pound');
INSERT INTO currency VALUES('dollar');
INSERT INTO currency VALUES('rupee');
INSERT INTO currency VALUES('yen');

INSERT INTO payment VALUES('paypal');
INSERT INTO payment VALUES('credit/debit card');
INSERT INTO payment VALUES('store money');

INSERT INTO stage VALUES('payment');
INSERT INTO stage VALUES('order');
INSERT INTO stage VALUES('transportation');
INSERT INTO stage VALUES('delivered');

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

INSERT INTO unblock_appeal(user_id,title,description) VALUES(5,'Cascade Twilight Bicycle Cascade Apple','Lighthouse Whisper Opulent Singing Lighthouse Singing Lighthouse Opulent Quicksilver Echo Ocean Harmony Starlight Radiance Saffron Dancing Sunshine Mystery Mountain Chocolate');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(6,'Firefly Treasure Carousel Dream Telescope','Trampoline Radiance Aurora Bamboo Carousel Starlight Firefly Firefly Carousel Firefly Rainbow Secret Butterfly Quicksilver Telescope Piano Bamboo Treasure Cascade Dragon');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(7,'Serendipity Whisper Piano Mystery Trampoline','Twilight Ocean Mountain Adventure Rainbow Starlight Carnival Reading Lighthouse Sunshine Velvet Ocean Moonlight Velvet Reading Lighthouse Horizon Dream Dragon Mirage');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(8,'Elephant Mountain Dream Galaxy Butterfly','Telescope Whimsical Euphoria Mystery Quicksilver Mountain Jumping Galaxy Butterfly Mystery Whisper Quicksilver Harmony Telescope Jumping Horizon Secret Lighthouse Radiance Ocean');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(9,'Quicksilver Euphoria Moonlight Bamboo Secret','Serendipity Jumping Writing Mirage Starlight Echo Carousel Whimsical Elephant Enchantment Zephyr Trampoline Trampoline Dancing Adventure Quicksilver Running Butterfly Swimming Carousel');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(10,'Elephant Mystery Swimming Potion Singing','Starlight Apple Castle Dancing Opulent Quicksilver Eating Enchantment Radiance Thinking Sunshine Piano Rainbow Singing Writing Aurora Secret Singing Swimming Opulent');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(11,'Chocolate Dancing Reading Potion Velvet','Enchantment Quicksilver Symphony Twilight Symphony Mystery Horizon Enchantment Reading Elephant Velvet Apple Echo Symphony Thinking Euphoria Eating Symphony Moonlight Writing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(12,'Dream Symphony Zephyr Dragon Whisper','Starlight Swimming Twilight Velvet Echo Dream Jumping Apple Cascade Euphoria Carousel Twilight Twilight Sleeping Carousel Symphony Running Bicycle Carnival Opulent');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(13,'Swimming Singing Serendipity Thinking Starlight','Trampoline Elephant Bicycle Mystery Mystery Tranquility Radiance Mountain Twilight Serendipity Swimming Adventure Horizon Eating Reading Twilight Butterfly Cascade Mountain Rainbow');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(14,'Dancing Eating Starlight Sunshine Velvet','Chocolate Whimsical Dragon Chocolate Moonlight Echo Bicycle Cascade Jumping Adventure Tranquility Twilight Whimsical Trampoline Sunshine Running Whimsical Horizon Firefly Dragon');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(15,'Carousel Serendipity Bamboo Writing Moonlight','Adventure Tranquility Velvet Elephant Treasure Trampoline Chocolate Dream Velvet Trampoline Butterfly Zephyr Secret Sleeping Velvet Harmony Treasure Cascade Serenade Telescope');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(16,'Euphoria Lighthouse Echo Horizon Serenade','Running Opulent Castle Opulent Swimming Horizon Carnival Reading Bamboo Lighthouse Horizon Harmony Zephyr Treasure Eating Lighthouse Lighthouse Saffron Adventure Serenade');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(17,'Zephyr Elephant Symphony Velvet Radiance','Echo Dream Tranquility Butterfly Whimsical Mystery Moonlight Ocean Adventure Reading Firefly Reading Velvet Potion Horizon Sunshine Galaxy Secret Telescope Symphony');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(18,'Aurora Cascade Chocolate Eating Butterfly','Reading Carousel Bicycle Whimsical Whimsical Jumping Potion Zephyr Harmony Harmony Serendipity Treasure Dragon Rainbow Serendipity Eating Twilight Apple Moonlight Mirage');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(19,'Piano Serenade Carnival Enchantment Whimsical','Secret Rainbow Starlight Sunshine Bamboo Singing Mirage Moonlight Opulent Carnival Treasure Trampoline Firefly Secret Symphony Apple Castle Swimming Serendipity Radiance');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(20,'Moonlight Harmony Rainbow Carousel Bicycle','Carnival Adventure Potion Secret Galaxy Sleeping Running Sunshine Sunshine Adventure Thinking Whisper Treasure Carnival Telescope Castle Whisper Sleeping Lighthouse Butterfly');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(21,'Dancing Serendipity Ocean Butterfly Apple','Carnival Castle Saffron Dancing Whisper Serenade Galaxy Singing Harmony Starlight Mystery Sleeping Apple Sleeping Dream Sleeping Euphoria Jumping Galaxy Velvet');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(22,'Zephyr Horizon Serendipity Bicycle Singing','Eating Enchantment Saffron Swimming Mountain Trampoline Telescope Horizon Galaxy Enchantment Potion Thinking Reading Writing Ocean Sunshine Sunshine Mystery Bamboo Singing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(23,'Jumping Galaxy Running Carnival Singing','Horizon Quicksilver Treasure Saffron Galaxy Thinking Radiance Euphoria Piano Euphoria Opulent Running Butterfly Twilight Zephyr Telescope Aurora Bamboo Velvet Telescope');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(24,'Twilight Carousel Reading Mystery Sunshine','Opulent Chocolate Mirage Reading Cascade Carnival Starlight Writing Dragon Writing Euphoria Swimming Mountain Writing Adventure Euphoria Jumping Firefly Dancing Dancing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(25,'Mirage Serendipity Velvet Eating Eating','Twilight Velvet Saffron Horizon Quicksilver Adventure Dancing Elephant Echo Echo Treasure Sunshine Quicksilver Sleeping Tranquility Rainbow Adventure Whimsical Echo Radiance');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(26,'Dancing Enchantment Symphony Singing Chocolate','Starlight Cascade Carousel Treasure Bicycle Cascade Bicycle Carousel Elephant Dragon Moonlight Zephyr Singing Quicksilver Quicksilver Bamboo Sleeping Zephyr Twilight Moonlight');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(27,'Echo Firefly Dragon Ocean Mystery','Aurora Carousel Swimming Trampoline Singing Rainbow Velvet Telescope Symphony Dragon Running Velvet Sunshine Horizon Cascade Elephant Jumping Cascade Sleeping Serendipity');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(28,'Mystery Dream Sleeping Secret Enchantment','Swimming Firefly Starlight Swimming Saffron Galaxy Mountain Quicksilver Carousel Dragon Cascade Radiance Writing Zephyr Ocean Castle Writing Euphoria Telescope Dream');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(29,'Bamboo Quicksilver Dragon Secret Butterfly','Bamboo Potion Apple Cascade Treasure Chocolate Aurora Zephyr Velvet Sleeping Singing Enchantment Opulent Chocolate Enchantment Butterfly Lighthouse Moonlight Whimsical Carousel');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(30,'Bamboo Symphony Serenade Trampoline Aurora','Sleeping Singing Horizon Quicksilver Bamboo Eating Sunshine Whimsical Jumping Mirage Eating Swimming Reading Cascade Swimming Piano Starlight Reading Whimsical Dancing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(31,'Opulent Galaxy Trampoline Whimsical Harmony','Piano Zephyr Dream Dragon Enchantment Enchantment Mirage Dragon Sunshine Adventure Horizon Swimming Twilight Bamboo Twilight Twilight Reading Reading Horizon Mystery');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(32,'Secret Writing Radiance Zephyr Firefly','Adventure Mountain Chocolate Reading Dream Trampoline Running Bamboo Starlight Aurora Adventure Zephyr Galaxy Trampoline Mirage Whisper Symphony Echo Cascade Zephyr');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(33,'Adventure Trampoline Bicycle Singing Ocean','Telescope Secret Rainbow Whisper Potion Secret Serendipity Carousel Euphoria Mirage Moonlight Mirage Elephant Running Potion Carousel Firefly Harmony Adventure Eating');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(34,'Dragon Butterfly Serendipity Symphony Firefly','Telescope Serendipity Sleeping Enchantment Butterfly Opulent Symphony Whimsical Whimsical Sleeping Firefly Mirage Rainbow Reading Serendipity Thinking Velvet Castle Euphoria Carnival');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(35,'Tranquility Bamboo Rainbow Rainbow Cascade','Quicksilver Twilight Zephyr Horizon Secret Bicycle Ocean Mountain Lighthouse Chocolate Galaxy Apple Zephyr Zephyr Adventure Starlight Elephant Secret Bicycle Radiance');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(36,'Moonlight Velvet Thinking Butterfly Galaxy','Writing Carousel Serendipity Moonlight Symphony Whimsical Chocolate Euphoria Trampoline Whimsical Dream Bamboo Secret Castle Writing Rainbow Symphony Tranquility Sunshine Carnival');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(37,'Bamboo Starlight Adventure Starlight Galaxy','Butterfly Apple Bicycle Apple Enchantment Carnival Elephant Mystery Moonlight Cascade Jumping Echo Whimsical Whimsical Bamboo Enchantment Writing Sleeping Adventure Elephant');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(38,'Starlight Jumping Zephyr Piano Harmony','Trampoline Reading Sunshine Galaxy Whisper Moonlight Tranquility Whimsical Cascade Lighthouse Saffron Opulent Echo Mountain Dragon Sunshine Bamboo Enchantment Lighthouse Symphony');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(39,'Echo Echo Sunshine Euphoria Eating','Tranquility Twilight Horizon Whimsical Apple Radiance Echo Secret Elephant Harmony Butterfly Mystery Swimming Castle Mirage Trampoline Rainbow Secret Starlight Firefly');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(40,'Quicksilver Trampoline Enchantment Tranquility Mountain','Mirage Secret Velvet Thinking Eating Secret Echo Ocean Firefly Adventure Serendipity Serendipity Thinking Rainbow Galaxy Singing Treasure Singing Rainbow Telescope');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(41,'Rainbow Thinking Whisper Running Harmony','Butterfly Piano Starlight Twilight Bamboo Enchantment Cascade Mirage Quicksilver Butterfly Tranquility Aurora Writing Mountain Butterfly Jumping Castle Ocean Mystery Secret');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(42,'Tranquility Potion Dream Reading Zephyr','Velvet Zephyr Euphoria Tranquility Harmony Jumping Twilight Euphoria Radiance Enchantment Sunshine Saffron Harmony Radiance Radiance Dancing Harmony Horizon Trampoline Bicycle');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(43,'Adventure Harmony Secret Running Sunshine','Rainbow Enchantment Elephant Secret Echo Mountain Sleeping Moonlight Adventure Aurora Euphoria Mystery Velvet Bicycle Bicycle Secret Butterfly Bicycle Ocean Cascade');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(44,'Chocolate Mirage Cascade Bamboo Moonlight','Serenade Thinking Horizon Mountain Rainbow Butterfly Dream Mountain Zephyr Bicycle Enchantment Dancing Echo Dancing Saffron Saffron Carousel Aurora Tranquility Rainbow');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(45,'Writing Horizon Ocean Ocean Galaxy','Bamboo Aurora Velvet Rainbow Trampoline Apple Firefly Swimming Thinking Ocean Reading Piano Singing Swimming Sleeping Secret Carousel Castle Castle Saffron');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(46,'Carnival Whimsical Velvet Castle Sleeping','Ocean Moonlight Velvet Twilight Dancing Rainbow Running Dancing Serenade Serendipity Butterfly Thinking Bamboo Zephyr Harmony Firefly Rainbow Writing Eating Galaxy');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(47,'Aurora Running Velvet Thinking Potion','Thinking Elephant Lighthouse Trampoline Running Elephant Zephyr Carousel Swimming Secret Piano Ocean Dream Eating Harmony Saffron Carousel Velvet Euphoria Symphony');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(48,'Twilight Sleeping Sleeping Trampoline Sunshine','Echo Twilight Twilight Running Treasure Quicksilver Firefly Swimming Secret Apple Bicycle Adventure Lighthouse Serendipity Butterfly Moonlight Tranquility Singing Saffron Tranquility');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(49,'Dream Ocean Sunshine Mountain Dream','Singing Swimming Singing Starlight Enchantment Enchantment Whisper Velvet Jumping Bamboo Moonlight Dancing Tranquility Serenade Rainbow Chocolate Writing Velvet Jumping Saffron');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(50,'Treasure Euphoria Adventure Dream Writing','Potion Trampoline Rainbow Firefly Opulent Symphony Trampoline Aurora Telescope Running Trampoline Whimsical Opulent Running Swimming Bicycle Butterfly Whisper Serendipity Treasure');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(51,'Trampoline Serendipity Mountain Whimsical Zephyr','Opulent Writing Serendipity Eating Dancing Moonlight Apple Rainbow Mountain Enchantment Moonlight Treasure Bicycle Castle Serenade Euphoria Swimming Telescope Radiance Quicksilver');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(52,'Moonlight Bamboo Trampoline Serenade Zephyr','Chocolate Chocolate Moonlight Sleeping Tranquility Enchantment Sunshine Tranquility Dragon Reading Radiance Carnival Treasure Whimsical Bicycle Ocean Chocolate Elephant Mirage Bicycle');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(53,'Running Galaxy Aurora Bamboo Firefly','Euphoria Horizon Castle Eating Sleeping Eating Lighthouse Running Enchantment Carousel Zephyr Aurora Echo Mirage Adventure Serenade Adventure Symphony Sunshine Dancing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(54,'Euphoria Dream Writing Treasure Whimsical','Starlight Chocolate Bicycle Writing Mystery Tranquility Apple Quicksilver Echo Chocolate Twilight Dragon Serenade Twilight Dream Moonlight Reading Dream Whisper Singing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(55,'Horizon Apple Ocean Quicksilver Echo','Moonlight Trampoline Bicycle Galaxy Zephyr Singing Sunshine Treasure Velvet Singing Reading Trampoline Adventure Jumping Secret Piano Treasure Cascade Trampoline Harmony');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(56,'Sleeping Zephyr Butterfly Mountain Telescope','Tranquility Serenade Twilight Singing Rainbow Rainbow Elephant Castle Echo Piano Serenade Adventure Dream Radiance Galaxy Tranquility Symphony Thinking Enchantment Mystery');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(57,'Elephant Lighthouse Quicksilver Carnival Sleeping','Eating Velvet Piano Singing Symphony Trampoline Sleeping Dream Horizon Mountain Radiance Whisper Starlight Twilight Firefly Zephyr Twilight Euphoria Opulent Piano');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(58,'Aurora Butterfly Whisper Bamboo Adventure','Eating Dragon Whimsical Serenade Radiance Serendipity Piano Whisper Sleeping Velvet Dream Rainbow Lighthouse Eating Castle Apple Castle Symphony Serenade Whisper');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(59,'Cascade Serenade Sleeping Dream Treasure','Dancing Saffron Ocean Bamboo Enchantment Elephant Moonlight Whisper Galaxy Horizon Saffron Jumping Dragon Apple Echo Serenade Serendipity Dancing Jumping Ocean');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(60,'Horizon Secret Carnival Whisper Bamboo','Running Firefly Thinking Telescope Carnival Harmony Apple Serendipity Dragon Aurora Eating Enchantment Symphony Ocean Dream Butterfly Lighthouse Opulent Adventure Tranquility');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(61,'Zephyr Horizon Treasure Euphoria Symphony','Thinking Serendipity Bamboo Starlight Euphoria Castle Lighthouse Adventure Singing Quicksilver Opulent Quicksilver Elephant Piano Whisper Bamboo Dream Aurora Writing Trampoline');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(62,'Firefly Sunshine Galaxy Secret Bicycle','Treasure Thinking Whimsical Singing Writing Horizon Sleeping Bamboo Whimsical Chocolate Quicksilver Horizon Swimming Treasure Chocolate Symphony Mountain Whimsical Secret Galaxy');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(63,'Apple Starlight Swimming Bicycle Carousel','Sleeping Chocolate Enchantment Mirage Velvet Starlight Butterfly Bamboo Enchantment Firefly Castle Mountain Carousel Dancing Potion Elephant Sunshine Galaxy Mystery Elephant');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(64,'Sleeping Enchantment Opulent Castle Apple','Carnival Apple Firefly Singing Velvet Piano Elephant Velvet Writing Castle Radiance Twilight Echo Carousel Dancing Quicksilver Jumping Starlight Sleeping Saffron');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(65,'Running Potion Lighthouse Echo Euphoria','Galaxy Serendipity Adventure Aurora Aurora Horizon Velvet Potion Zephyr Ocean Whisper Galaxy Swimming Secret Whisper Butterfly Serendipity Potion Whimsical Singing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(66,'Bicycle Zephyr Zephyr Tranquility Ocean','Adventure Saffron Dragon Dragon Writing Whisper Sunshine Euphoria Mystery Saffron Butterfly Castle Aurora Trampoline Lighthouse Mountain Quicksilver Starlight Lighthouse Writing');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(67,'Dragon Piano Cascade Writing Running','Dancing Reading Rainbow Ocean Sleeping Chocolate Butterfly Mountain Moonlight Mystery Symphony Opulent Velvet Writing Echo Sunshine Sleeping Echo Euphoria Thinking');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(68,'Eating Mirage Firefly Bamboo Running','Potion Moonlight Twilight Aurora Piano Writing Lighthouse Dragon Tranquility Bicycle Cascade Eating Zephyr Zephyr Radiance Carnival Galaxy Carousel Twilight Velvet');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(69,'Dream Jumping Carousel Euphoria Saffron','Writing Writing Opulent Butterfly Jumping Trampoline Enchantment Reading Echo Thinking Thinking Serenade Whisper Whimsical Quicksilver Secret Whimsical Reading Cascade Cascade');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(70,'Firefly Tranquility Harmony Symphony Ocean','Reading Moonlight Harmony Rainbow Elephant Piano Castle Velvet Reading Secret Dream Bicycle Piano Sunshine Tranquility Castle Saffron Bamboo Starlight Moonlight');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(71,'Saffron Lighthouse Writing Dragon Dancing','Apple Running Whimsical Carnival Sleeping Butterfly Tranquility Rainbow Moonlight Carousel Bamboo Velvet Opulent Chocolate Zephyr Zephyr Treasure Carousel Carnival Starlight');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(72,'Whimsical Writing Tranquility Serendipity Dancing','Jumping Thinking Singing Carousel Tranquility Telescope Secret Bamboo Aurora Opulent Radiance Swimming Apple Firefly Bicycle Velvet Serenade Potion Running Secret');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(73,'Butterfly Echo Mountain Dream Twilight','Moonlight Twilight Moonlight Rainbow Bamboo Running Swimming Bicycle Whimsical Adventure Carnival Trampoline Enchantment Swimming Trampoline Carousel Velvet Radiance Radiance Eating');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(74,'Sunshine Bamboo Mountain Trampoline Reading','Euphoria Trampoline Sunshine Aurora Telescope Castle Enchantment Secret Ocean Ocean Dream Running Writing Butterfly Adventure Zephyr Butterfly Serenade Horizon Moonlight');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(75,'Running Galaxy Galaxy Jumping Velvet','Moonlight Butterfly Radiance Mirage Singing Velvet Bicycle Mountain Singing Firefly Thinking Harmony Mountain Ocean Serendipity Lighthouse Harmony Ocean Treasure Echo');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(76,'Bicycle Eating Enchantment Galaxy Horizon','Telescope Zephyr Moonlight Dancing Cascade Twilight Elephant Bamboo Thinking Bamboo Enchantment Thinking Writing Carousel Sleeping Whisper Jumping Bamboo Mystery Elephant');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(77,'Potion Castle Chocolate Writing Saffron','Cascade Jumping Piano Zephyr Starlight Harmony Bamboo Thinking Serenade Whisper Symphony Starlight Potion Thinking Horizon Butterfly Trampoline Whisper Ocean Dream');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(78,'Adventure Reading Symphony Trampoline Sleeping','Saffron Aurora Mountain Twilight Quicksilver Twilight Dancing Twilight Twilight Serenade Singing Aurora Cascade Velvet Galaxy Bamboo Mountain Dream Butterfly Butterfly');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(79,'Velvet Carnival Mirage Serendipity Castle','Running Rainbow Bicycle Dancing Symphony Sleeping Thinking Opulent Velvet Lighthouse Opulent Chocolate Velvet Sunshine Rainbow Mirage Cascade Aurora Euphoria Bamboo');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(80,'Butterfly Bamboo Castle Reading Twilight','Ocean Whisper Carousel Sunshine Saffron Castle Lighthouse Saffron Starlight Whimsical Swimming Chocolate Dragon Mirage Butterfly Velvet Writing Whisper Dream Castle');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(81,'Mountain Castle Reading Mirage Whisper','Horizon Swimming Sunshine Ocean Mirage Bicycle Trampoline Sunshine Quicksilver Whisper Twilight Cascade Jumping Galaxy Serendipity Reading Potion Castle Opulent Swimming');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(82,'Twilight Whimsical Velvet Writing Sleeping','Trampoline Lighthouse Ocean Horizon Serendipity Saffron Secret Dream Bicycle Euphoria Butterfly Mystery Dancing Secret Whimsical Quicksilver Horizon Potion Mirage Mountain');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(83,'Jumping Eating Piano Writing Writing','Opulent Opulent Jumping Horizon Dream Sunshine Ocean Zephyr Zephyr Velvet Rainbow Butterfly Horizon Bamboo Butterfly Saffron Velvet Piano Rainbow Saffron');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(84,'Carousel Secret Serenade Whimsical Opulent','Telescope Moonlight Dancing Enchantment Mirage Castle Telescope Swimming Telescope Dancing Dream Carnival Enchantment Running Castle Singing Rainbow Trampoline Chocolate Treasure');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(85,'Sleeping Ocean Bicycle Tranquility Mountain','Potion Firefly Whisper Euphoria Radiance Dragon Ocean Apple Telescope Elephant Dream Galaxy Harmony Whisper Zephyr Enchantment Telescope Piano Secret Lighthouse');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(86,'Velvet Apple Enchantment Ocean Dancing','Dancing Trampoline Serenade Starlight Whisper Radiance Carnival Whisper Thinking Bicycle Mountain Carnival Opulent Serendipity Lighthouse Bamboo Whisper Symphony Velvet Starlight');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(87,'Sleeping Mystery Chocolate Mountain Rainbow','Zephyr Writing Castle Castle Ocean Apple Running Bicycle Dragon Dancing Velvet Elephant Velvet Galaxy Carnival Writing Echo Cascade Rainbow Reading');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(88,'Chocolate Piano Chocolate Harmony Zephyr','Mirage Running Carnival Moonlight Radiance Enchantment Treasure Symphony Velvet Adventure Sunshine Lighthouse Butterfly Mystery Sleeping Adventure Running Rainbow Adventure Serenade');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(89,'Radiance Lighthouse Firefly Velvet Starlight','Adventure Writing Piano Serendipity Bicycle Velvet Whimsical Galaxy Thinking Mirage Apple Bicycle Reading Lighthouse Ocean Ocean Dancing Chocolate Horizon Enchantment');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(90,'Butterfly Potion Mirage Dream Whimsical','Starlight Sunshine Jumping Mountain Aurora Potion Harmony Mystery Galaxy Dragon Serendipity Symphony Serenade Butterfly Symphony Sunshine Radiance Mountain Galaxy Whimsical');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(91,'Sunshine Thinking Secret Carnival Lighthouse','Quicksilver Carousel Serenade Moonlight Butterfly Whimsical Zephyr Galaxy Mirage Starlight Velvet Mountain Potion Radiance Eating Echo Twilight Carousel Dancing Enchantment');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(92,'Serendipity Apple Symphony Quicksilver Eating','Ocean Chocolate Whimsical Piano Swimming Euphoria Carousel Serenade Enchantment Serenade Trampoline Whimsical Telescope Horizon Quicksilver Galaxy Dancing Bamboo Secret Telescope');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(93,'Sleeping Galaxy Twilight Zephyr Potion','Chocolate Bamboo Writing Moonlight Dragon Singing Eating Euphoria Rainbow Serendipity Eating Sunshine Enchantment Saffron Carnival Castle Tranquility Whimsical Serenade Adventure');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(94,'Serenade Zephyr Lighthouse Serenade Treasure','Whimsical Twilight Singing Potion Butterfly Serendipity Saffron Whisper Mirage Apple Dream Treasure Whimsical Dragon Rainbow Firefly Saffron Radiance Enchantment Chocolate');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(95,'Potion Secret Starlight Moonlight Running','Mountain Bamboo Treasure Jumping Running Serendipity Velvet Cascade Firefly Whimsical Zephyr Jumping Adventure Velvet Carousel Euphoria Radiance Radiance Horizon Telescope');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(96,'Mirage Radiance Apple Sunshine Reading','Carousel Euphoria Horizon Eating Carnival Galaxy Reading Dancing Sunshine Mirage Trampoline Moonlight Adventure Mountain Aurora Apple Firefly Zephyr Harmony Carnival');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(97,'Symphony Mountain Adventure Galaxy Serendipity','Opulent Quicksilver Ocean Euphoria Castle Aurora Velvet Starlight Carnival Mirage Tranquility Firefly Rainbow Opulent Apple Carousel Serendipity Chocolate Rainbow Tranquility');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(98,'Apple Zephyr Starlight Thinking Velvet','Carnival Harmony Trampoline Serenade Serendipity Running Writing Dream Sleeping Trampoline Mystery Trampoline Quicksilver Sunshine Telescope Treasure Harmony Dream Radiance Velvet');
INSERT INTO unblock_appeal(user_id,title,description) VALUES(99,'Serenade Jumping Firefly Echo Tranquility','Bicycle Lighthouse Trampoline Galaxy Running Reading Mirage Swimming Carnival Cascade Cascade Tranquility Piano Velvet Whimsical Writing Velvet Euphoria Mystery Adventure');

INSERT INTO authenticated_notification(user_id,notification_type) VALUES(37,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(56,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(7,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(63,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(35,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(21,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(69,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(94,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(29,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(25,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(6,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(40,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(7,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(23,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(72,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(87,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(92,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(49,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(58,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(68,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(35,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(72,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(14,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(78,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(8,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(94,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(31,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(33,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(47,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(42,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(60,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(68,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(19,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(85,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(14,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(85,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(11,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(80,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(29,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(84,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(25,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(42,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(59,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(7,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(42,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(6,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(46,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(14,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(8,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(78,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(44,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(41,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(29,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(47,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(58,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(87,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(72,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(38,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(78,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(51,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(39,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(49,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(91,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(53,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(86,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(45,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(36,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(47,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(94,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(89,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(8,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(93,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(67,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(71,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(52,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(77,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(40,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(94,'purchaseinfo_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(80,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(61,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(25,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(31,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(64,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(93,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(66,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(43,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(24,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(63,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(66,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(81,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(32,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(9,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(87,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(15,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(71,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(17,'payment_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(20,'instock_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(94,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(96,'pricechange_notification');
INSERT INTO authenticated_notification(user_id,notification_type) VALUES(22,'purchaseinfo_notification');

INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Whimsical Echo','Mirage Reading Horizon Mountain Firefly Enchantment Dancing Mirage Piano Serendipity Opulent Zephyr Running Horizon Horizon Serenade Quicksilver Aurora Apple Dancing Treasure Firefly Reading Castle Zephyr Quicksilver Tranquility Serendipity Zephyr Saffron Saffron Tranquility Mystery Mirage Apple Carnival Telescope Echo Symphony Saffron',8,8,4805,'Paisley Jayden','Theo Ezekiel','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Opulent Aurora Adventure','Symphony Velvet Apple Dream Starlight Mystery Harmony Singing Cascade Lighthouse Apple Serenade Sleeping Reading Dancing Serendipity Elephant Galaxy Serendipity Dancing Butterfly Whisper Zephyr Eating Saffron Moonlight Eating Potion Mountain Cascade Whimsical Echo Potion Euphoria Castle Running Apple Bicycle Lighthouse Tranquility',84,67.2,1759,'Delilah Elizabeth','Grayson Muhammad','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Elephant Jumping','Serenade Sunshine Horizon Radiance Tranquility Ocean Whimsical Serenade Dragon Serendipity Thinking Singing Carousel Symphony Mirage Carnival Dream Ocean Harmony Castle Euphoria Swimming Adventure Carnival Swimming Enchantment Serenade Moonlight Treasure Reading Ocean Velvet Thinking Velvet Twilight Mountain Elephant Mountain Rainbow Firefly',32,28.8,2060,'Emma Luna','Harper Penelope','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Symphony Echo','Telescope Adventure Apple Bicycle Dancing Jumping Sunshine Singing Piano Chocolate Trampoline Symphony Telescope Eating Carousel Whimsical Apple Swimming Bamboo Saffron Sleeping Trampoline Symphony Lighthouse Echo Symphony Horizon Treasure Dream Whimsical Zephyr Writing Carousel Eating Starlight Telescope Carousel Opulent Zephyr Whimsical',97,97,6693,'Isaiah Emily','Theo Kai','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Telescope Zephyr','Zephyr Starlight Secret Sunshine Moonlight Writing Piano Velvet Bamboo Piano Carousel Writing Swimming Ocean Whimsical Carousel Writing Whisper Bamboo Aurora Carousel Lighthouse Secret Dancing Rainbow Velvet Dragon Whisper Serenade Euphoria Running Mystery Quicksilver Running Lighthouse Radiance Aurora Writing Piano Mystery',3,0.75,9957,'Wyatt Hudson','Penelope Luke','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serendipity Ocean Sunshine','Ocean Apple Firefly Chocolate Piano Potion Enchantment Thinking Aurora Opulent Butterfly Dragon Thinking Saffron Galaxy Butterfly Moonlight Dragon Zephyr Whisper Chocolate Sunshine Opulent Serenade Whimsical Saffron Enchantment Opulent Singing Serenade Sleeping Bamboo Dancing Castle Euphoria Quicksilver Trampoline Elephant Euphoria Tranquility',27,20.25,7326,'Avery Samuel','Daniel Kai','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Cascade Reading','Firefly Mirage Zephyr Serenade Potion Opulent Velvet Potion Mirage Harmony Potion Serenade Harmony Swimming Velvet Moonlight Swimming Echo Eating Writing Aurora Apple Elephant Twilight Mirage Dancing Serendipity Dancing Trampoline Piano Castle Chocolate Euphoria Butterfly Aurora Thinking Apple Swimming Adventure Sleeping',27,27,9795,'Owen Amelia','Luke Charlotte','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Secret Writing','Mountain Sleeping Eating Running Whimsical Aurora Whisper Cascade Cascade Dancing Piano Secret Apple Firefly Mountain Telescope Dragon Serenade Thinking Symphony Serenade Treasure Rainbow Symphony Twilight Sunshine Bicycle Euphoria Euphoria Tranquility Adventure Sleeping Swimming Jumping Harmony Dragon Apple Chocolate Carousel Radiance',20,5.0,7204,'Mateo Scarlett','Miles David','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Zephyr Reading','Echo Secret Potion Carousel Tranquility Mirage Starlight Echo Carnival Carousel Serendipity Dream Whimsical Writing Sleeping Horizon Sunshine Echo Quicksilver Treasure Thinking Tranquility Harmony Rainbow Whisper Singing Apple Serendipity Velvet Saffron Butterfly Firefly Running Symphony Swimming Firefly Dancing Dragon Aurora Bamboo',75,75,6742,'Carter Elijah','Elena Nova','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Castle Enchantment','Chocolate Eating Secret Zephyr Ocean Mystery Adventure Jumping Butterfly Secret Echo Dancing Twilight Whimsical Singing Running Enchantment Telescope Carousel Bamboo Ocean Potion Apple Velvet Piano Radiance Potion Mountain Twilight Elephant Piano Enchantment Saffron Carnival Trampoline Opulent Potion Opulent Enchantment Galaxy',80,64.0,3922,'Paisley Aiden','Ezekiel Zoey','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Carnival Lighthouse','Apple Zephyr Opulent Bamboo Whisper Horizon Piano Euphoria Carousel Radiance Zephyr Starlight Chocolate Serenade Carousel Rainbow Trampoline Eating Cascade Writing Reading Telescope Secret Quicksilver Carousel Mountain Bamboo Quicksilver Euphoria Swimming Writing Treasure Sunshine Elephant Dancing Horizon Reading Harmony Cascade Carnival',13,13,1145,'Elias Amelia','Ivy Luna','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Swimming Reading','Butterfly Bicycle Galaxy Enchantment Euphoria Sunshine Reading Chocolate Reading Ocean Saffron Piano Velvet Eating Horizon Velvet Ocean Chocolate Treasure Carousel Starlight Secret Galaxy Thinking Lighthouse Ocean Saffron Treasure Firefly Twilight Serendipity Symphony Saffron Serenade Sunshine Chocolate Elephant Eating Carnival Trampoline',61,61,8221,'Grayson Isabella','Hazel Kai','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Firefly Zephyr','Carousel Serendipity Singing Writing Carousel Moonlight Treasure Adventure Velvet Writing Running Bamboo Eating Mirage Butterfly Quicksilver Galaxy Castle Moonlight Mystery Reading Starlight Adventure Potion Dragon Mirage Telescope Rainbow Serendipity Chocolate Moonlight Serendipity Aurora Reading Treasure Twilight Rainbow Reading Eating Elephant',64,12.799999999999997,7659,'Isaiah Leo','Ivy Sofia','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Horizon Enchantment','Galaxy Symphony Radiance Zephyr Zephyr Singing Carnival Horizon Aurora Symphony Twilight Galaxy Aurora Running Twilight Harmony Whimsical Saffron Telescope Mystery Mystery Writing Mountain Symphony Potion Telescope Reading Galaxy Euphoria Radiance Reading Telescope Tranquility Whisper Aurora Firefly Velvet Whisper Saffron Galaxy',93,69.75,3043,'Sebastian Paisley','Sofia James','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Radiance Chocolate','Saffron Ocean Running Galaxy Butterfly Butterfly Carnival Carnival Writing Piano Mystery Moonlight Writing Castle Velvet Dragon Potion Carnival Tranquility Telescope Dragon Echo Whimsical Sunshine Mountain Swimming Dancing Radiance Symphony Moonlight Horizon Treasure Velvet Cascade Opulent Tranquility Secret Carnival Thinking Carnival',8,6.0,9353,'Michael Riley','Matthew Lucas','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Eating Writing','Cascade Symphony Starlight Lighthouse Opulent Castle Potion Aurora Echo Opulent Symphony Elephant Echo Twilight Adventure Treasure Eating Firefly Galaxy Thinking Dream Piano Tranquility Chocolate Bicycle Aurora Velvet Cascade Whimsical Cascade Whimsical Rainbow Writing Echo Eating Adventure Treasure Butterfly Sleeping Serenade',20,15.0,2772,'Penelope Isla','Noah Chloe','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Firefly Mountain','Bamboo Eating Swimming Secret Reading Rainbow Whisper Elephant Mountain Chocolate Singing Dancing Writing Bicycle Secret Opulent Bamboo Velvet Singing Lighthouse Singing Twilight Singing Symphony Radiance Tranquility Serendipity Piano Opulent Eating Carousel Starlight Starlight Carousel Echo Apple Bamboo Mountain Whimsical Chocolate',70,63.0,2715,'Willow Ethan','Elizabeth Gabriel','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Secret Swimming','Harmony Mystery Bamboo Rainbow Dragon Ocean Jumping Quicksilver Radiance Moonlight Chocolate Swimming Zephyr Serenade Enchantment Opulent Carnival Serendipity Butterfly Trampoline Telescope Serendipity Piano Bamboo Running Aurora Opulent Butterfly Eating Moonlight Starlight Galaxy Moonlight Echo Ocean Echo Dragon Echo Enchantment Writing',79,63.2,4748,'Layla Benjamin','Amelia Jacob','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Echo Castle','Ocean Potion Dragon Quicksilver Ocean Mirage Sunshine Carnival Dancing Velvet Chocolate Velvet Aurora Serendipity Euphoria Zephyr Mountain Whimsical Trampoline Reading Serenade Mountain Jumping Cascade Treasure Potion Whimsical Quicksilver Galaxy Whisper Carnival Adventure Quicksilver Moonlight Carousel Aurora Twilight Enchantment Mirage Tranquility',83,66.4,6567,'Josiah Theo','Leo Jayden','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Velvet Zephyr','Bamboo Cascade Symphony Whisper Dream Mystery Horizon Ocean Bicycle Reading Dancing Serenade Reading Serenade Reading Elephant Horizon Moonlight Dragon Starlight Carousel Swimming Rainbow Butterfly Telescope Velvet Saffron Castle Secret Carnival Whimsical Sunshine Elephant Running Radiance Tranquility Whimsical Reading Harmony Sunshine',12,10.8,5465,'Gianna Camila','Violet Delilah','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Singing Reading','Apple Sunshine Rainbow Singing Apple Running Twilight Quicksilver Radiance Potion Symphony Trampoline Telescope Elephant Euphoria Serenade Twilight Dragon Dream Treasure Tranquility Opulent Lighthouse Butterfly Quicksilver Apple Zephyr Sleeping Mystery Chocolate Whisper Tranquility Harmony Dream Echo Twilight Butterfly Rainbow Swimming Running',9,2.25,8933,'Willow Maverick','Jackson Aurora','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Dragon Potion','Whimsical Butterfly Potion Running Butterfly Serendipity Aurora Saffron Potion Singing Rainbow Sunshine Jumping Euphoria Quicksilver Euphoria Adventure Telescope Potion Dream Secret Serenade Cascade Twilight Trampoline Aurora Telescope Mirage Castle Potion Dragon Chocolate Telescope Dancing Piano Harmony Ocean Jumping Symphony Velvet',70,35.0,1451,'Ava Hazel','Ezra Emily','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Aurora Horizon','Serenade Carousel Enchantment Velvet Serenade Potion Piano Dream Aurora Carousel Bamboo Velvet Running Harmony Reading Velvet Piano Treasure Serenade Radiance Twilight Elephant Whimsical Adventure Enchantment Serendipity Velvet Thinking Castle Serenade Sleeping Twilight Sleeping Reading Echo Harmony Mirage Rainbow Treasure Firefly',57,45.6,1551,'Jacob Lily','Abigail Logan','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Moonlight Telescope Aurora','Telescope Saffron Tranquility Mirage Cascade Lighthouse Horizon Ocean Starlight Tranquility Tranquility Firefly Saffron Mirage Firefly Trampoline Tranquility Swimming Ocean Quicksilver Galaxy Carnival Opulent Reading Treasure Firefly Jumping Rainbow Cascade Trampoline Singing Dancing Trampoline Sleeping Piano Opulent Firefly Running Saffron Mountain',66,26.4,2976,'Isla Mateo','Charlotte Theo','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Opulent Running','Aurora Thinking Ocean Starlight Singing Running Eating Eating Swimming Reading Whisper Echo Chocolate Dancing Potion Velvet Velvet Thinking Reading Adventure Dancing Carnival Quicksilver Thinking Mirage Chocolate Potion Carousel Mystery Sleeping Harmony Dream Symphony Mountain Enchantment Sleeping Velvet Mountain Saffron Serenade',11,8.8,5923,'Mia Paisley','Lucas Isla','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Echo Lighthouse','Aurora Euphoria Lighthouse Telescope Carnival Trampoline Chocolate Galaxy Dancing Treasure Reading Eating Butterfly Euphoria Carnival Dream Dancing Whimsical Symphony Thinking Chocolate Reading Serenade Ocean Trampoline Whimsical Euphoria Thinking Enchantment Quicksilver Moonlight Harmony Bamboo Starlight Potion Treasure Echo Serendipity Castle Dragon',52,41.6,813,'Gianna Camila','Elena Henry','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Ocean Mystery','Enchantment Castle Thinking Dancing Bamboo Adventure Opulent Opulent Thinking Elephant Sunshine Rainbow Moonlight Bicycle Dream Saffron Mystery Opulent Bicycle Aurora Tranquility Dancing Rainbow Dream Thinking Carousel Treasure Dragon Treasure Velvet Tranquility Dragon Bicycle Horizon Carousel Rainbow Lighthouse Harmony Telescope Piano',67,16.75,434,'Elena Elizabeth','Sofia Noah','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Horizon Serenade','Tranquility Starlight Carousel Running Bamboo Reading Apple Running Euphoria Potion Thinking Quicksilver Whisper Saffron Rainbow Castle Twilight Carousel Whisper Singing Sleeping Dancing Potion Twilight Dream Euphoria Euphoria Trampoline Aurora Firefly Opulent Elephant Castle Reading Jumping Thinking Galaxy Eating Echo Euphoria',34,30.6,3877,'Hudson Waylon','Emily Naomi','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Writing Symphony','Butterfly Butterfly Secret Sleeping Horizon Tranquility Tranquility Echo Singing Velvet Tranquility Dragon Serenade Sunshine Dream Eating Twilight Whimsical Echo Mountain Thinking Butterfly Symphony Rainbow Moonlight Lighthouse Bicycle Saffron Carousel Chocolate Bamboo Singing Dream Singing Euphoria Swimming Radiance Bicycle Carousel Carousel',24,18.0,9033,'Nova Amelia','Luca Willow','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Writing Bicycle','Whisper Dancing Ocean Ocean Swimming Castle Jumping Piano Twilight Serendipity Velvet Twilight Running Cascade Starlight Mystery Bamboo Whisper Galaxy Sunshine Moonlight Running Rainbow Dragon Ocean Chocolate Singing Elephant Dream Sleeping Whimsical Sleeping Aurora Running Echo Moonlight Serendipity Harmony Treasure Symphony',6,6,6201,'Harper Madison','James Benjamin','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Carnival Running','Serendipity Butterfly Piano Dragon Bicycle Thinking Aurora Euphoria Treasure Butterfly Radiance Castle Harmony Galaxy Radiance Thinking Whisper Dragon Dancing Thinking Symphony Opulent Carousel Serendipity Harmony Firefly Dream Velvet Cascade Apple Trampoline Galaxy Castle Whisper Thinking Whisper Reading Adventure Firefly Writing',30,27.0,8599,'Maya Layla','Leilani Jackson','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Dancing Dancing','Starlight Tranquility Chocolate Aurora Swimming Sleeping Tranquility Dragon Symphony Dancing Horizon Whimsical Echo Carousel Velvet Quicksilver Treasure Rainbow Mystery Dream Dancing Telescope Mystery Thinking Zephyr Mystery Whimsical Apple Mirage Writing Bamboo Trampoline Horizon Chocolate Thinking Serenade Dancing Horizon Saffron Euphoria',90,45.0,1164,'Miles Aria','Muhammad Mila','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Firefly Mystery','Radiance Echo Euphoria Harmony Horizon Dream Piano Swimming Serendipity Radiance Swimming Velvet Galaxy Serendipity Carnival Lighthouse Sunshine Mountain Moonlight Dancing Quicksilver Moonlight Bamboo Dancing Radiance Running Dragon Quicksilver Opulent Potion Cascade Castle Bamboo Castle Treasure Velvet Euphoria Treasure Chocolate Velvet',58,43.5,6691,'Elena Theodore','Luke Gianna','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Opulent Harmony Carnival','Secret Tranquility Carnival Rainbow Opulent Eating Symphony Opulent Elephant Sunshine Potion Aurora Aurora Aurora Moonlight Carousel Potion Butterfly Treasure Starlight Twilight Swimming Mirage Singing Horizon Singing Firefly Writing Bicycle Piano Horizon Elephant Dancing Eating Starlight Velvet Saffron Running Dream Whisper',54,13.5,9970,'Chloe Chloe','Zoe Nova','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Lighthouse Elephant','Serenade Singing Mystery Sunshine Twilight Velvet Writing Saffron Carnival Tranquility Echo Potion Cascade Cascade Eating Sleeping Bicycle Chocolate Eating Horizon Potion Cascade Mirage Sleeping Velvet Piano Mountain Aurora Velvet Running Carnival Running Running Velvet Running Reading Castle Reading Galaxy Radiance',67,13.399999999999999,5833,'Jack Owen','Hudson Mateo','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Velvet Aurora','Elephant Ocean Galaxy Euphoria Velvet Secret Dancing Quicksilver Dream Trampoline Velvet Running Quicksilver Velvet Telescope Chocolate Castle Galaxy Castle Velvet Sunshine Echo Treasure Mountain Trampoline Saffron Castle Bamboo Mirage Jumping Jumping Swimming Mountain Lighthouse Galaxy Carousel Reading Jumping Serenade Jumping',14,11.2,3686,'Jayden James','Mila Jayden','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Bicycle Twilight','Bamboo Eating Running Carousel Quicksilver Writing Jumping Euphoria Twilight Mountain Aurora Secret Thinking Elephant Sunshine Dragon Carousel Harmony Opulent Moonlight Carnival Writing Mystery Potion Treasure Starlight Zephyr Jumping Whimsical Writing Whimsical Opulent Sleeping Telescope Chocolate Galaxy Potion Potion Butterfly Sleeping',83,62.25,5880,'Scarlett Lily','Theodore Delilah','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Chocolate Sleeping','Quicksilver Euphoria Serendipity Secret Trampoline Thinking Aurora Carousel Adventure Moonlight Running Aurora Trampoline Carnival Eating Carousel Saffron Reading Reading Tranquility Velvet Thinking Piano Whimsical Adventure Aurora Secret Aurora Mountain Serendipity Velvet Tranquility Secret Ocean Galaxy Quicksilver Symphony Galaxy Sleeping Treasure',86,77.4,3203,'Matthew Isabella','Naomi Gabriel','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Moonlight Secret','Castle Dancing Serenade Enchantment Butterfly Carnival Sleeping Euphoria Symphony Ocean Running Treasure Carousel Bamboo Castle Velvet Harmony Potion Moonlight Rainbow Mountain Writing Adventure Euphoria Velvet Quicksilver Whisper Rainbow Enchantment Bicycle Adventure Sunshine Reading Eating Firefly Jumping Zephyr Rainbow Chocolate Lighthouse',49,36.75,6296,'Eliana Jacob','Leo Alexander','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Serendipity Running','Horizon Sunshine Twilight Mountain Mirage Serenade Potion Jumping Serendipity Mirage Dream Reading Zephyr Apple Bicycle Horizon Dragon Jumping Bamboo Ocean Serendipity Radiance Castle Whisper Reading Serendipity Piano Piano Trampoline Ocean Carousel Sleeping Mountain Piano Velvet Swimming Radiance Reading Reading Cascade',57,22.800000000000004,7783,'Asher Alexander','Riley Daniel','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Butterfly Twilight','Running Apple Serendipity Singing Writing Swimming Sleeping Dream Piano Reading Apple Castle Running Mystery Dream Castle Piano Serenade Sunshine Moonlight Moonlight Potion Adventure Mirage Euphoria Chocolate Horizon Treasure Mystery Horizon Running Mountain Elephant Apple Enchantment Whisper Opulent Mystery Opulent Ocean',56,22.4,7390,'Lucas Ethan','Mason Kai','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Dragon Running','Whimsical Opulent Secret Mirage Carousel Dancing Dancing Piano Apple Velvet Potion Cascade Opulent Thinking Dragon Firefly Whimsical Bamboo Tranquility Castle Potion Swimming Velvet Mountain Telescope Euphoria Mirage Treasure Lighthouse Secret Sunshine Apple Zephyr Potion Castle Rainbow Bicycle Velvet Firefly Galaxy',38,30.4,3145,'Hazel James','Sophia Josiah','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Potion Mirage','Starlight Castle Velvet Velvet Adventure Moonlight Piano Serenade Galaxy Cascade Bamboo Whimsical Jumping Symphony Trampoline Chocolate Rainbow Treasure Carousel Velvet Echo Swimming Enchantment Chocolate Dragon Writing Euphoria Quicksilver Telescope Starlight Cascade Zephyr Adventure Zephyr Twilight Thinking Horizon Symphony Castle Starlight',10,9.0,3860,'Muhammad Maya','Chloe Jayden','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Serendipity Mystery','Firefly Reading Sunshine Treasure Mirage Castle Writing Piano Starlight Secret Whisper Writing Adventure Bamboo Singing Running Galaxy Serendipity Whimsical Mirage Trampoline Singing Echo Velvet Mystery Singing Galaxy Twilight Horizon Moonlight Thinking Potion Mystery Quicksilver Cascade Lighthouse Telescope Symphony Singing Zephyr',63,47.25,7846,'Aiden Isabella','Mila David','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Horizon Dragon','Starlight Moonlight Serendipity Opulent Bamboo Radiance Radiance Carousel Butterfly Carnival Euphoria Mirage Echo Dragon Singing Piano Running Whimsical Cascade Moonlight Singing Velvet Jumping Sleeping Jumping Telescope Sleeping Tranquility Carnival Opulent Whisper Echo Carousel Running Serendipity Carnival Reading Adventure Mountain Aurora',90,36.0,9493,'Logan Elijah','Nova Leilani','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Echo Echo','Chocolate Carousel Sunshine Carnival Ocean Thinking Swimming Castle Sunshine Swimming Carnival Bicycle Radiance Swimming Mirage Mountain Elephant Saffron Telescope Rainbow Twilight Secret Treasure Lighthouse Chocolate Enchantment Butterfly Sleeping Quicksilver Chocolate Horizon Mirage Eating Running Elephant Secret Aurora Adventure Galaxy Bamboo',30,27.0,6643,'Muhammad William','Elijah Olivia','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Dancing Thinking','Sunshine Sleeping Enchantment Dream Reading Echo Dream Harmony Velvet Ocean Writing Dancing Mystery Galaxy Carnival Swimming Bicycle Saffron Sunshine Mystery Harmony Symphony Bamboo Quicksilver Zephyr Starlight Opulent Thinking Singing Twilight Zephyr Tranquility Serenade Eating Whisper Bamboo Butterfly Whisper Velvet Jumping',30,7.5,3402,'Isaiah Carter','Matthew Ethan','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Trampoline Writing','Trampoline Carousel Galaxy Apple Castle Adventure Thinking Sleeping Reading Apple Symphony Serenade Firefly Ocean Enchantment Symphony Jumping Whimsical Dream Harmony Bamboo Mountain Moonlight Symphony Zephyr Bicycle Euphoria Enchantment Lighthouse Dragon Dragon Starlight Bamboo Harmony Potion Radiance Chocolate Zephyr Euphoria Bicycle',7,3.5,7278,'Miles Violet','Jackson Ivy','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Zephyr Harmony','Echo Dancing Elephant Lighthouse Aurora Piano Trampoline Harmony Mystery Thinking Mirage Reading Aurora Elephant Jumping Writing Chocolate Dream Swimming Echo Serendipity Serendipity Dream Horizon Sunshine Dream Moonlight Trampoline Potion Ocean Dream Galaxy Castle Carousel Euphoria Rainbow Potion Bamboo Opulent Echo',76,57.0,1678,'Zoey Violet','Mila Willow','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Thinking Piano','Velvet Swimming Mountain Moonlight Velvet Mountain Tranquility Quicksilver Mystery Chocolate Dream Opulent Singing Firefly Apple Elephant Secret Potion Cascade Jumping Firefly Telescope Serenade Castle Eating Velvet Mountain Telescope Lighthouse Horizon Aurora Aurora Chocolate Aurora Harmony Radiance Singing Reading Mountain Castle',4,3.2,2483,'Miles Delilah','Elias Maya','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Enchantment Serenade','Carnival Harmony Firefly Eating Whimsical Singing Cascade Bicycle Chocolate Lighthouse Aurora Dragon Adventure Treasure Galaxy Reading Twilight Carnival Mountain Euphoria Carnival Carousel Singing Bamboo Quicksilver Starlight Bicycle Opulent Swimming Telescope Serenade Writing Whisper Starlight Sleeping Reading Saffron Swimming Castle Dream',100,20.0,236,'Sebastian Elijah','Ezekiel Athena','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Opulent Running','Velvet Serendipity Cascade Potion Dragon Singing Saffron Serenade Adventure Serendipity Whimsical Radiance Serendipity Apple Sleeping Dragon Saffron Trampoline Telescope Potion Euphoria Trampoline Enchantment Telescope Thinking Whimsical Adventure Starlight Butterfly Horizon Aurora Carousel Euphoria Trampoline Euphoria Bicycle Sunshine Mystery Singing Mountain',48,24.0,4911,'Kai Emily','Lucas Evelyn','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Dancing Thinking','Butterfly Echo Singing Dragon Harmony Aurora Horizon Carousel Lighthouse Velvet Echo Radiance Butterfly Chocolate Piano Dream Whimsical Carnival Secret Cascade Singing Euphoria Eating Zephyr Tranquility Symphony Echo Reading Swimming Firefly Firefly Bamboo Aurora Velvet Elephant Running Running Adventure Horizon Castle',86,17.200000000000003,3763,'Riley Madison','Emilia Luca','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Lighthouse Horizon','Apple Serenade Thinking Elephant Singing Thinking Firefly Twilight Potion Carousel Twilight Moonlight Ocean Quicksilver Elephant Harmony Ocean Enchantment Starlight Quicksilver Moonlight Writing Tranquility Sleeping Starlight Dancing Enchantment Mystery Symphony Carousel Tranquility Secret Chocolate Cascade Elephant Dragon Enchantment Sleeping Twilight Singing',36,27.0,8738,'Mason Noah','Oliver Chloe','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Echo Mystery','Bicycle Potion Aurora Adventure Running Moonlight Thinking Jumping Symphony Euphoria Apple Velvet Velvet Radiance Horizon Treasure Secret Euphoria Ocean Potion Swimming Chocolate Piano Potion Velvet Horizon Writing Zephyr Potion Moonlight Treasure Ocean Harmony Elephant Dream Saffron Secret Elephant Sunshine Galaxy',28,22.4,5563,'Grace Penelope','Sophia Paisley','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Radiance Velvet','Jumping Ocean Eating Jumping Telescope Velvet Eating Mirage Serendipity Adventure Swimming Thinking Swimming Enchantment Firefly Whimsical Serenade Rainbow Adventure Whisper Quicksilver Whimsical Mirage Trampoline Lighthouse Rainbow Saffron Telescope Singing Swimming Chocolate Starlight Potion Zephyr Starlight Cascade Aurora Mystery Starlight Dancing',90,22.5,2195,'Emma Camila','Evelyn Michael','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Euphoria Carousel','Opulent Potion Piano Saffron Ocean Treasure Starlight Mirage Saffron Euphoria Serendipity Moonlight Bicycle Butterfly Rainbow Thinking Whisper Twilight Running Echo Potion Rainbow Secret Carnival Velvet Velvet Writing Sleeping Galaxy Saffron Euphoria Swimming Mystery Harmony Zephyr Carnival Dream Reading Moonlight Mountain',14,5.6,3947,'Julian Levi','Eliana Logan','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Whisper Writing','Chocolate Carousel Butterfly Dancing Serenade Carnival Running Bamboo Velvet Adventure Eating Whimsical Chocolate Starlight Whisper Adventure Reading Starlight Velvet Firefly Zephyr Eating Saffron Chocolate Ocean Singing Running Euphoria Symphony Twilight Bicycle Dream Symphony Velvet Starlight Castle Secret Velvet Mountain Carnival',8,1.5999999999999996,260,'Ava Luke','Isla Logan','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Firefly Butterfly','Eating Apple Dancing Piano Radiance Carousel Twilight Writing Thinking Trampoline Thinking Dancing Jumping Twilight Whimsical Elephant Dragon Aurora Thinking Eating Velvet Zephyr Carnival Sleeping Serendipity Whisper Horizon Chocolate Starlight Cascade Bicycle Swimming Swimming Harmony Whisper Starlight Singing Reading Elephant Sleeping',9,4.5,425,'Julian Alexander','Camila Eleanor','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Mountain Euphoria','Twilight Firefly Running Echo Twilight Cascade Dragon Starlight Telescope Treasure Dream Whimsical Writing Harmony Lighthouse Harmony Bicycle Horizon Apple Serendipity Horizon Telescope Elephant Piano Dream Castle Zephyr Serenade Moonlight Serendipity Piano Whisper Lighthouse Apple Bamboo Whisper Thinking Carousel Aurora Dancing',43,32.25,5350,'Emma Mason','Olivia Elijah','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Whisper Singing','Sunshine Singing Rainbow Saffron Aurora Dragon Dragon Singing Dragon Horizon Starlight Sleeping Symphony Bamboo Writing Horizon Euphoria Singing Chocolate Serenade Bamboo Mystery Chocolate Tranquility Rainbow Secret Eating Singing Mountain Butterfly Running Firefly Velvet Whisper Serendipity Serenade Symphony Trampoline Bamboo Elephant',28,5.599999999999998,6123,'Liam Mason','Liam Paisley','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Quicksilver Telescope','Serendipity Lighthouse Firefly Symphony Aurora Dancing Whimsical Mystery Butterfly Castle Whimsical Tranquility Piano Writing Writing Potion Mystery Writing Galaxy Ocean Reading Saffron Opulent Carousel Quicksilver Starlight Chocolate Cascade Bicycle Echo Piano Butterfly Telescope Singing Running Aurora Elephant Eating Rainbow Writing',32,16.0,4359,'Luna Theo','Leo Daniel','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Castle Opulent Dream','Velvet Elephant Velvet Sunshine Swimming Symphony Horizon Whisper Dream Radiance Echo Sunshine Mystery Treasure Mirage Dream Twilight Swimming Mirage Telescope Firefly Sleeping Quicksilver Dancing Horizon Harmony Horizon Bicycle Whimsical Trampoline Chocolate Euphoria Lighthouse Sleeping Jumping Mirage Jumping Singing Thinking Running',100,80.0,7036,'Santiago William','Charlotte Luke','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Potion Sunshine','Firefly Piano Writing Writing Castle Dragon Dancing Aurora Bicycle Harmony Twilight Harmony Running Bicycle Mystery Twilight Aurora Chocolate Thinking Dancing Moonlight Mystery Potion Elephant Castle Whimsical Enchantment Serenade Writing Sleeping Thinking Bicycle Trampoline Rainbow Firefly Serenade Piano Harmony Horizon Trampoline',51,51,2641,'Muhammad Aria','Luke Noah','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Bamboo Twilight','Euphoria Jumping Thinking Aurora Potion Echo Symphony Jumping Mirage Radiance Jumping Aurora Sleeping Bamboo Potion Serendipity Bicycle Bicycle Moonlight Mountain Dream Reading Cascade Mystery Whisper Radiance Potion Echo Moonlight Enchantment Writing Mystery Mirage Dancing Zephyr Mystery Swimming Galaxy Ocean Chocolate',78,78,2071,'Emily Jacob','Maverick Delilah','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Treasure Sunshine','Elephant Dragon Butterfly Apple Whisper Ocean Horizon Treasure Eating Eating Euphoria Piano Adventure Telescope Sunshine Serendipity Elephant Saffron Echo Elephant Twilight Thinking Thinking Horizon Chocolate Mystery Starlight Starlight Reading Dancing Moonlight Dragon Butterfly Velvet Dream Galaxy Aurora Writing Trampoline Serenade',95,19.0,2267,'Scarlett Carter','Theodore Mateo','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Eating Potion','Thinking Tranquility Eating Reading Twilight Chocolate Dream Adventure Mirage Treasure Potion Elephant Eating Secret Reading Mountain Quicksilver Reading Dragon Opulent Opulent Whisper Sunshine Radiance Butterfly Mountain Swimming Jumping Running Rainbow Aurora Dream Treasure Ocean Telescope Moonlight Castle Zephyr Starlight Reading',57,11.399999999999999,9922,'Maya Sofia','Michael Asher','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Cascade Trampoline','Tranquility Tranquility Quicksilver Trampoline Bicycle Serenade Trampoline Rainbow Serenade Echo Adventure Adventure Bicycle Aurora Aurora Mystery Eating Chocolate Quicksilver Running Aurora Horizon Sunshine Saffron Moonlight Ocean Enchantment Serendipity Treasure Elephant Dragon Velvet Symphony Swimming Serenade Sunshine Reading Harmony Reading Dancing',91,22.75,7709,'David Nova','William Nora','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Starlight Dragon','Quicksilver Mystery Echo Saffron Bicycle Piano Apple Twilight Thinking Mirage Moonlight Whisper Castle Serendipity Reading Opulent Butterfly Velvet Serendipity Trampoline Twilight Horizon Moonlight Twilight Velvet Castle Trampoline Bamboo Writing Symphony Enchantment Writing Twilight Velvet Castle Whimsical Carnival Eating Eating Zephyr',80,80,5496,'Gianna Jayden','Paisley Levi','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Jumping Writing Dancing','Serendipity Mirage Aurora Mirage Trampoline Carousel Dream Secret Tranquility Horizon Velvet Aurora Radiance Ocean Mountain Starlight Serenade Treasure Reading Eating Singing Starlight Twilight Tranquility Telescope Singing Lighthouse Secret Starlight Mystery Quicksilver Velvet Velvet Galaxy Eating Dream Serenade Sunshine Echo Whisper',8,8,8415,'Penelope Emily','Eleanor Elias','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Bamboo Running','Euphoria Serenade Starlight Butterfly Zephyr Starlight Eating Jumping Velvet Carnival Velvet Enchantment Enchantment Horizon Serendipity Whimsical Carousel Opulent Serenade Dragon Serenade Bicycle Dragon Serenade Dancing Ocean Running Secret Rainbow Aurora Velvet Dancing Lighthouse Galaxy Running Jumping Trampoline Reading Chocolate Zephyr',60,15.0,7869,'Theodore Abigail','Hazel Chloe','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Firefly Bamboo','Mountain Quicksilver Aurora Carousel Lighthouse Apple Writing Rainbow Whisper Velvet Enchantment Jumping Mountain Telescope Velvet Whimsical Rainbow Galaxy Writing Euphoria Serenade Starlight Reading Bamboo Rainbow Enchantment Quicksilver Lighthouse Butterfly Running Chocolate Sleeping Tranquility Trampoline Trampoline Zephyr Aurora Bamboo Dream Running',79,59.25,7856,'Eliana Hudson','Ezekiel Santiago','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Velvet Swimming','Twilight Chocolate Horizon Butterfly Horizon Singing Running Echo Zephyr Castle Quicksilver Quicksilver Echo Chocolate Mountain Whimsical Mirage Quicksilver Tranquility Zephyr Radiance Bamboo Jumping Treasure Reading Velvet Dancing Saffron Dragon Firefly Bamboo Symphony Quicksilver Echo Eating Velvet Twilight Eating Opulent Rainbow',4,1.0,9699,'David Leo','Daniel Athena','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Quicksilver Apple','Treasure Reading Galaxy Whisper Elephant Horizon Reading Tranquility Aurora Bamboo Eating Thinking Potion Butterfly Butterfly Writing Euphoria Adventure Aurora Bamboo Mirage Mountain Eating Firefly Aurora Adventure Euphoria Telescope Eating Adventure Rainbow Elephant Adventure Aurora Euphoria Radiance Cascade Opulent Zephyr Starlight',13,10.4,3461,'Charlotte Aiden','Jacob Elijah','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Enchantment Radiance','Moonlight Mirage Bamboo Singing Castle Secret Serenade Mystery Euphoria Bicycle Bicycle Bicycle Carnival Cascade Tranquility Starlight Serendipity Bicycle Euphoria Eating Harmony Velvet Opulent Swimming Enchantment Enchantment Carousel Carousel Serenade Firefly Apple Starlight Sleeping Lighthouse Secret Mystery Opulent Whimsical Galaxy Bicycle',44,11.0,3616,'Waylon Chloe','Camila Sophia','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Velvet Adventure','Serenade Carnival Velvet Harmony Bicycle Butterfly Serendipity Serendipity Running Piano Dancing Sleeping Aurora Serenade Radiance Radiance Tranquility Carnival Trampoline Butterfly Serendipity Saffron Thinking Whisper Chocolate Whisper Horizon Tranquility Jumping Sunshine Cascade Bicycle Dragon Harmony Elephant Apple Quicksilver Trampoline Galaxy Harmony',83,74.7,9256,'Mila Charlotte','Benjamin Aria','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Running Whisper','Dream Serendipity Bamboo Swimming Carnival Tranquility Butterfly Harmony Carnival Reading Jumping Lighthouse Apple Dragon Opulent Velvet Butterfly Galaxy Zephyr Horizon Opulent Symphony Dragon Firefly Saffron Saffron Carnival Whisper Elephant Rainbow Elephant Moonlight Serenade Mirage Rainbow Velvet Sleeping Treasure Enchantment Sunshine',90,81.0,96,'Amelia Logan','Sophia Luna','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Twilight Whimsical','Echo Elephant Radiance Dancing Whimsical Jumping Aurora Tranquility Writing Symphony Symphony Telescope Starlight Mirage Radiance Reading Mountain Carousel Serendipity Horizon Adventure Moonlight Zephyr Enchantment Velvet Bamboo Piano Carousel Saffron Thinking Velvet Apple Quicksilver Singing Sleeping Sleeping Tranquility Writing Carousel Tranquility',24,19.2,5211,'Luca Emily','Mateo Liam','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Jumping Jumping','Writing Sunshine Echo Twilight Dream Firefly Sleeping Singing Symphony Cascade Enchantment Whisper Dancing Running Sunshine Castle Writing Treasure Euphoria Mirage Reading Mystery Bamboo Treasure Eating Serendipity Mystery Zephyr Euphoria Chocolate Bamboo Piano Zephyr Ocean Radiance Dream Firefly Adventure Zephyr Radiance',85,34.0,1511,'Ella Jayden','Ivy Lucas','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Sunshine Zephyr','Serendipity Rainbow Secret Apple Lighthouse Mystery Piano Elephant Velvet Elephant Firefly Jumping Carousel Jumping Apple Bamboo Jumping Secret Running Trampoline Serendipity Singing Treasure Bicycle Cascade Dancing Mystery Enchantment Velvet Radiance Aurora Eating Sleeping Trampoline Quicksilver Dream Zephyr Opulent Tranquility Euphoria',48,38.4,4164,'Avery Noah','Amelia Riley','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Twilight Starlight','Quicksilver Apple Dragon Mountain Velvet Starlight Serendipity Trampoline Trampoline Aurora Moonlight Bamboo Mirage Cascade Symphony Ocean Jumping Serenade Bamboo Elephant Bamboo Butterfly Carnival Reading Elephant Aurora Lighthouse Elephant Sunshine Carnival Saffron Quicksilver Singing Harmony Eating Thinking Lighthouse Serenade Telescope Swimming',33,33,6752,'Hazel Josiah','Eleanor Luca','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Thinking Cascade','Symphony Harmony Horizon Bamboo Writing Harmony Enchantment Mountain Trampoline Whimsical Mountain Moonlight Horizon Opulent Running Elephant Treasure Radiance Radiance Rainbow Dragon Saffron Treasure Rainbow Velvet Apple Dragon Serenade Zephyr Reading Whisper Twilight Harmony Adventure Aurora Castle Dancing Reading Moonlight Sunshine',35,28.0,6350,'Emma Sebastian','Lucas Ava','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Rainbow Dragon','Running Symphony Aurora Adventure Thinking Apple Mystery Starlight Mirage Dancing Whimsical Whimsical Sunshine Piano Moonlight Elephant Moonlight Lighthouse Mountain Thinking Writing Sunshine Telescope Serenade Cascade Harmony Running Zephyr Galaxy Chocolate Enchantment Lighthouse Thinking Mirage Writing Symphony Echo Cascade Symphony Radiance',69,69,3690,'Luna Oliver','Abigail Noah','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Cascade Quicksilver','Velvet Horizon Running Apple Dancing Velvet Elephant Jumping Apple Dancing Dragon Carnival Sleeping Enchantment Moonlight Telescope Running Radiance Whimsical Starlight Rainbow Cascade Saffron Mystery Mystery Quicksilver Adventure Telescope Carnival Jumping Starlight Carnival Trampoline Sunshine Treasure Saffron Treasure Galaxy Serendipity Twilight',69,17.25,2515,'Ellie Ezekiel','Leo Logan','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Zephyr Tranquility','Adventure Telescope Bicycle Moonlight Treasure Dragon Piano Twilight Eating Lighthouse Trampoline Echo Dancing Galaxy Dancing Chocolate Harmony Velvet Harmony Sunshine Dancing Singing Galaxy Aurora Singing Cascade Treasure Potion Butterfly Elephant Mirage Harmony Dancing Singing Whisper Sleeping Dancing Rainbow Saffron Elephant',34,17.0,7439,'Ezekiel Alexander','Daniel Nova','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Harmony Dream','Castle Starlight Mirage Sunshine Mystery Jumping Treasure Serendipity Moonlight Dragon Treasure Euphoria Telescope Symphony Sunshine Velvet Treasure Bamboo Sunshine Potion Singing Reading Piano Elephant Aurora Castle Bicycle Quicksilver Sleeping Singing Echo Whimsical Velvet Opulent Twilight Jumping Writing Radiance Mystery Quicksilver',88,17.599999999999994,4886,'Aria Chloe','Ellie Gianna','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Elephant Treasure','Eating Bicycle Symphony Chocolate Ocean Carnival Symphony Apple Cascade Treasure Zephyr Bicycle Piano Firefly Velvet Velvet Velvet Euphoria Castle Telescope Mystery Enchantment Jumping Velvet Bamboo Sunshine Mirage Aurora Serendipity Adventure Opulent Radiance Quicksilver Tranquility Tranquility Whisper Swimming Tranquility Twilight Trampoline',24,21.6,3852,'Matthew Mila','Grace Layla','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Mystery Eating','Lighthouse Harmony Bicycle Dancing Galaxy Velvet Trampoline Mountain Running Velvet Opulent Tranquility Thinking Dream Echo Carnival Aurora Lighthouse Opulent Bamboo Running Cascade Mirage Serendipity Echo Carnival Running Mirage Quicksilver Carnival Opulent Mountain Dragon Serendipity Zephyr Bamboo Chocolate Symphony Dragon Harmony',16,4.0,3238,'Hazel Daniel','Layla Ezra','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Treasure Thinking','Echo Writing Reading Butterfly Jumping Thinking Enchantment Tranquility Ocean Enchantment Writing Saffron Apple Piano Apple Ocean Writing Jumping Mountain Jumping Treasure Euphoria Echo Adventure Mirage Thinking Lighthouse Bamboo Sunshine Moonlight Running Aurora Moonlight Elephant Carousel Symphony Mountain Firefly Moonlight Mountain',3,1.5,1964,'Maya Mila','Sebastian Liam','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Mirage Saffron','Eating Apple Enchantment Potion Firefly Elephant Starlight Quicksilver Bamboo Bamboo Trampoline Enchantment Running Secret Castle Moonlight Rainbow Telescope Bicycle Mystery Velvet Mountain Carnival Dancing Starlight Apple Eating Moonlight Aurora Mirage Lighthouse Trampoline Running Thinking Dragon Sunshine Whisper Carousel Dragon Dancing',13,11.7,7944,'Henry Lucas','Henry Gianna','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Eating Firefly','Whisper Starlight Bamboo Dragon Treasure Sleeping Serenade Quicksilver Firefly Harmony Singing Velvet Moonlight Reading Starlight Galaxy Elephant Elephant Tranquility Galaxy Serenade Eating Galaxy Harmony Radiance Aurora Writing Mystery Trampoline Mountain Treasure Writing Starlight Eating Zephyr Reading Jumping Whisper Butterfly Enchantment',100,20.0,8517,'Athena Lucas','Alexander Luca','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Zephyr Mountain','Carousel Aurora Cascade Horizon Sleeping Castle Reading Velvet Piano Sunshine Trampoline Bamboo Treasure Ocean Piano Apple Mountain Tranquility Jumping Quicksilver Reading Mountain Mountain Radiance Symphony Bamboo Carnival Mirage Rainbow Cascade Mystery Tranquility Saffron Dancing Castle Quicksilver Serendipity Velvet Starlight Thinking',72,57.6,7852,'Miles Luca','Aria Paisley','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Bicycle Enchantment','Cascade Reading Mirage Tranquility Treasure Radiance Eating Potion Saffron Enchantment Dancing Running Jumping Horizon Quicksilver Potion Echo Swimming Cascade Whisper Starlight Trampoline Swimming Adventure Twilight Telescope Elephant Sleeping Lighthouse Dream Saffron Lighthouse Whisper Mystery Starlight Bamboo Rainbow Carnival Butterfly Castle',19,19,1628,'Elena Isla','Ellie Kai','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Dragon Castle','Ocean Trampoline Galaxy Quicksilver Enchantment Trampoline Trampoline Carousel Running Swimming Running Euphoria Aurora Running Zephyr Echo Thinking Whimsical Serenade Dream Cascade Mystery Elephant Bicycle Twilight Rainbow Swimming Eating Radiance Galaxy Horizon Writing Starlight Mountain Adventure Bamboo Carousel Piano Moonlight Chocolate',77,77,5380,'Waylon Harper','Evelyn Evelyn','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Dream Velvet','Castle Moonlight Lighthouse Carnival Whimsical Ocean Mountain Apple Mystery Mountain Mirage Mystery Singing Treasure Jumping Eating Singing Firefly Bamboo Dancing Treasure Radiance Zephyr Bamboo Horizon Zephyr Echo Euphoria Rainbow Elephant Jumping Serendipity Cascade Symphony Swimming Apple Bamboo Dream Secret Euphoria',48,38.4,18,'Grace Olivia','Ezekiel Nova','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Chocolate Bicycle','Tranquility Writing Bamboo Radiance Elephant Castle Sunshine Twilight Euphoria Euphoria Reading Mystery Bicycle Apple Dream Butterfly Euphoria Saffron Eating Telescope Thinking Elephant Swimming Saffron Adventure Symphony Adventure Writing Saffron Saffron Bamboo Carnival Sleeping Symphony Euphoria Trampoline Mirage Moonlight Jumping Ocean',14,5.6,5811,'Zoe Gabriel','Aria Evelyn','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Radiance Trampoline','Saffron Dream Carousel Chocolate Eating Quicksilver Elephant Echo Piano Adventure Horizon Sunshine Butterfly Velvet Reading Chocolate Piano Ocean Running Whisper Mirage Velvet Butterfly Mirage Harmony Echo Opulent Mountain Twilight Velvet Starlight Castle Eating Singing Apple Carousel Potion Tranquility Carnival Bamboo',20,20,7603,'Mateo Ezra','Mia Madison','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Running Dancing','Dancing Zephyr Whimsical Opulent Harmony Mountain Trampoline Whisper Dragon Singing Adventure Whisper Radiance Symphony Velvet Bamboo Carnival Telescope Velvet Elephant Galaxy Serendipity Symphony Sunshine Opulent Tranquility Bamboo Quicksilver Rainbow Horizon Euphoria Lighthouse Aurora Radiance Harmony Symphony Writing Carnival Apple Adventure',2,2,3680,'Owen Sofia','Isaiah Muhammad','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Piano Saffron','Jumping Mirage Ocean Potion Piano Harmony Rainbow Reading Harmony Piano Elephant Moonlight Lighthouse Galaxy Moonlight Moonlight Apple Firefly Rainbow Firefly Adventure Apple Sleeping Saffron Saffron Eating Aurora Jumping Firefly Adventure Bamboo Piano Opulent Mystery Jumping Euphoria Opulent Treasure Secret Eating',94,47.0,1418,'Amelia Aurora','Luca Ellie','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Apple Symphony','Piano Apple Zephyr Echo Moonlight Moonlight Dragon Cascade Whimsical Twilight Trampoline Enchantment Carousel Lighthouse Eating Sunshine Moonlight Piano Reading Telescope Quicksilver Dream Velvet Elephant Serenade Adventure Jumping Mystery Firefly Potion Bamboo Mountain Mirage Eating Horizon Aurora Chocolate Castle Saffron Galaxy',89,44.5,5042,'Wyatt Harper','William Naomi','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Sleeping Opulent','Adventure Rainbow Aurora Ocean Horizon Rainbow Whisper Carousel Reading Aurora Mystery Twilight Serendipity Ocean Serendipity Aurora Telescope Jumping Whimsical Moonlight Butterfly Elephant Firefly Potion Euphoria Galaxy Butterfly Eating Zephyr Telescope Thinking Velvet Velvet Telescope Dream Opulent Lighthouse Potion Dragon Harmony',64,64,9602,'Hudson Elena','Elijah Santiago','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Firefly Twilight','Thinking Rainbow Euphoria Dream Telescope Apple Telescope Bamboo Tranquility Dragon Whisper Euphoria Dream Serenade Opulent Castle Starlight Chocolate Sunshine Moonlight Butterfly Opulent Dream Adventure Telescope Whimsical Mirage Radiance Symphony Tranquility Mirage Secret Sleeping Running Running Carnival Reading Mirage Secret Treasure',91,36.4,4195,'Mila Liam','Matthew Eleanor','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Serenade Tranquility','Velvet Chocolate Rainbow Mirage Sunshine Galaxy Serendipity Cascade Sunshine Velvet Whimsical Adventure Dancing Serenade Velvet Sunshine Zephyr Thinking Dragon Potion Treasure Velvet Velvet Castle Ocean Castle Radiance Zephyr Twilight Aurora Jumping Quicksilver Tranquility Swimming Horizon Running Whimsical Rainbow Castle Chocolate',93,23.25,6901,'Owen Willow','Hazel Isaiah','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Ocean Writing Serendipity','Castle Sunshine Telescope Bicycle Lighthouse Whisper Trampoline Symphony Mystery Butterfly Whisper Jumping Echo Symphony Whisper Eating Radiance Galaxy Swimming Galaxy Jumping Sleeping Firefly Galaxy Saffron Radiance Rainbow Mountain Carousel Sunshine Sleeping Whimsical Harmony Chocolate Thinking Apple Elephant Firefly Cascade Enchantment',23,23,3285,'Carter Oliver','Harper Emma','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Symphony Jumping','Cascade Whisper Moonlight Treasure Treasure Moonlight Whisper Mirage Dream Singing Saffron Tranquility Echo Running Castle Dragon Twilight Tranquility Jumping Rainbow Whisper Singing Velvet Horizon Mystery Velvet Jumping Enchantment Mirage Mirage Serenade Mountain Twilight Chocolate Reading Thinking Echo Dream Thinking Echo',87,87,9993,'Jackson Ellie','Elias Liam','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Lighthouse Tranquility','Sleeping Whimsical Secret Sunshine Moonlight Treasure Piano Harmony Writing Potion Whimsical Treasure Horizon Dragon Rainbow Galaxy Rainbow Velvet Whimsical Velvet Velvet Running Carousel Thinking Carousel Moonlight Swimming Bamboo Jumping Starlight Opulent Piano Telescope Quicksilver Treasure Twilight Whimsical Carousel Whisper Trampoline',14,12.6,3600,'Daniel Maya','Henry Mateo','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Cascade Whisper','Whisper Rainbow Whimsical Bamboo Reading Bicycle Reading Trampoline Bamboo Butterfly Echo Elephant Radiance Castle Cascade Tranquility Butterfly Saffron Reading Enchantment Rainbow Swimming Running Cascade Cascade Singing Twilight Telescope Opulent Carnival Radiance Sleeping Mirage Elephant Reading Castle Saffron Echo Opulent Echo',5,5,1861,'Elias Alexander','Chloe Elias','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bamboo Castle Dancing','Sleeping Apple Bicycle Echo Telescope Mystery Adventure Whisper Swimming Twilight Telescope Aurora Adventure Zephyr Telescope Swimming Echo Horizon Firefly Radiance Eating Apple Sleeping Trampoline Running Horizon Serendipity Secret Dream Horizon Rainbow Swimming Horizon Butterfly Trampoline Opulent Carousel Mystery Dream Whisper',6,2.4000000000000004,5810,'Zoey Oliver','Ava Ella','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Velvet Radiance','Opulent Starlight Ocean Quicksilver Moonlight Dragon Writing Euphoria Secret Butterfly Zephyr Mountain Adventure Bicycle Echo Aurora Trampoline Bamboo Running Rainbow Zephyr Carnival Velvet Piano Whimsical Symphony Rainbow Telescope Mirage Dragon Eating Carnival Potion Starlight Tranquility Twilight Reading Potion Mountain Swimming',37,7.399999999999999,4785,'Isla Wyatt','Hudson Grace','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Elephant Sleeping','Swimming Sleeping Dancing Elephant Dream Opulent Whimsical Ocean Carousel Trampoline Secret Potion Whimsical Saffron Whisper Carnival Lighthouse Serenade Chocolate Saffron Ocean Serendipity Bamboo Sleeping Eating Starlight Zephyr Treasure Elephant Treasure Sleeping Velvet Mirage Carnival Whisper Moonlight Galaxy Running Bicycle Harmony',23,17.25,7319,'Emily Elizabeth','Michael Levi','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Treasure Velvet','Mirage Tranquility Velvet Castle Chocolate Whimsical Eating Symphony Adventure Writing Eating Trampoline Carnival Radiance Symphony Bicycle Carnival Aurora Symphony Symphony Tranquility Horizon Serenade Carousel Quicksilver Mountain Moonlight Secret Elephant Aurora Aurora Potion Firefly Opulent Galaxy Whisper Galaxy Writing Twilight Writing',99,74.25,980,'Jacob Aria','Mateo Luca','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Moonlight Cascade Ocean','Horizon Thinking Running Bamboo Dream Dream Starlight Velvet Mountain Jumping Castle Starlight Rainbow Mystery Tranquility Secret Chocolate Butterfly Carnival Ocean Symphony Dream Enchantment Echo Adventure Secret Galaxy Mystery Euphoria Zephyr Carnival Telescope Elephant Singing Starlight Aurora Carousel Galaxy Telescope Serendipity',75,30.0,555,'Aurora Madison','Elena Amelia','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Piano Galaxy','Swimming Swimming Whisper Trampoline Starlight Writing Dream Butterfly Potion Opulent Jumping Firefly Harmony Serendipity Chocolate Galaxy Secret Thinking Castle Symphony Harmony Tranquility Enchantment Firefly Quicksilver Whisper Piano Rainbow Euphoria Dancing Elephant Serendipity Sleeping Sunshine Harmony Opulent Symphony Whisper Eating Serendipity',70,70,6253,'Mia Ava','Ezekiel Sophia','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Jumping Running','Carousel Dragon Potion Radiance Sleeping Whisper Dancing Trampoline Adventure Butterfly Secret Radiance Serenade Radiance Zephyr Thinking Whimsical Echo Chocolate Potion Symphony Serenade Bamboo Piano Telescope Telescope Trampoline Mirage Cascade Radiance Carousel Sunshine Velvet Eating Bamboo Whisper Serenade Running Zephyr Horizon',44,8.799999999999997,455,'Lily Sophia','Penelope Luke','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Sunshine Enchantment','Galaxy Rainbow Serendipity Zephyr Reading Thinking Sunshine Potion Harmony Enchantment Trampoline Carousel Running Secret Swimming Swimming Writing Quicksilver Chocolate Castle Castle Galaxy Swimming Treasure Elephant Thinking Mountain Symphony Castle Mystery Apple Thinking Bamboo Quicksilver Eating Echo Eating Symphony Butterfly Apple',64,64,2519,'Ava Miles','Nova Charlotte','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Ocean Jumping','Chocolate Carousel Butterfly Castle Sleeping Twilight Bamboo Velvet Bamboo Echo Dream Thinking Jumping Carousel Reading Horizon Tranquility Radiance Dream Mirage Adventure Whisper Moonlight Tranquility Adventure Dream Radiance Singing Ocean Serenade Carnival Echo Zephyr Symphony Reading Tranquility Telescope Horizon Swimming Moonlight',30,24.0,871,'Charlotte Ethan','Ezekiel Elias','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Writing Piano','Telescope Writing Sunshine Moonlight Sleeping Jumping Mirage Butterfly Eating Quicksilver Eating Moonlight Sunshine Zephyr Dancing Firefly Bamboo Sunshine Chocolate Zephyr Harmony Ocean Adventure Castle Cascade Thinking Butterfly Ocean Sunshine Reading Telescope Enchantment Dream Carousel Trampoline Rainbow Tranquility Adventure Lighthouse Euphoria',59,47.2,925,'William Jack','Camila Delilah','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Chocolate Piano','Bamboo Lighthouse Velvet Trampoline Enchantment Castle Rainbow Aurora Symphony Serenade Dancing Firefly Carnival Symphony Treasure Carnival Horizon Chocolate Singing Tranquility Quicksilver Galaxy Eating Elephant Whisper Butterfly Harmony Chocolate Mirage Whisper Swimming Velvet Enchantment Velvet Serenade Euphoria Mirage Castle Eating Firefly',93,74.4,9411,'Theo Asher','Luna Harper','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Bicycle Twilight','Whimsical Quicksilver Sunshine Echo Moonlight Chocolate Whisper Whisper Cascade Velvet Lighthouse Dancing Butterfly Thinking Whisper Serendipity Piano Piano Mystery Aurora Cascade Tranquility Serendipity Carnival Dragon Adventure Echo Treasure Enchantment Adventure Galaxy Euphoria Singing Thinking Saffron Echo Elephant Horizon Reading Adventure',98,49.0,4453,'Delilah Waylon','Amelia Ava','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Castle Butterfly Thinking','Dragon Serenade Horizon Running Thinking Cascade Eating Treasure Chocolate Mountain Radiance Velvet Eating Secret Horizon Starlight Rainbow Zephyr Dream Opulent Echo Saffron Whisper Radiance Dancing Elephant Whisper Potion Thinking Reading Singing Castle Potion Elephant Saffron Treasure Adventure Sunshine Radiance Firefly',96,86.4,7557,'Jayden Carter','Olivia Gianna','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Horizon Cascade','Enchantment Galaxy Running Eating Mystery Horizon Cascade Bicycle Chocolate Velvet Chocolate Whisper Elephant Castle Harmony Galaxy Galaxy Mystery Butterfly Bicycle Bicycle Writing Butterfly Telescope Apple Echo Telescope Enchantment Carousel Eating Chocolate Adventure Eating Sleeping Mirage Saffron Swimming Eating Bicycle Piano',32,8.0,7540,'Nova Theo','Emilia Eliana','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Rainbow Enchantment','Jumping Harmony Symphony Cascade Velvet Firefly Horizon Secret Tranquility Potion Lighthouse Serendipity Dancing Enchantment Sunshine Twilight Mirage Symphony Carousel Dream Running Adventure Serendipity Potion Castle Castle Radiance Starlight Dragon Echo Mirage Jumping Serenade Secret Treasure Cascade Apple Ocean Dream Swimming',76,19.0,6277,'Delilah Amelia','David Elijah','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Swimming Harmony','Enchantment Whisper Galaxy Sleeping Singing Serenade Saffron Chocolate Secret Velvet Adventure Adventure Trampoline Swimming Telescope Adventure Adventure Cascade Mystery Apple Singing Serenade Trampoline Dream Carousel Enchantment Singing Potion Eating Firefly Velvet Harmony Velvet Singing Twilight Elephant Whisper Zephyr Euphoria Bamboo',69,62.1,2569,'Leilani Delilah','Logan Elizabeth','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Carnival Saffron','Galaxy Treasure Zephyr Sunshine Elephant Piano Ocean Symphony Horizon Potion Saffron Echo Whisper Dancing Enchantment Bamboo Symphony Treasure Piano Writing Eating Adventure Eating Bamboo Apple Saffron Bicycle Telescope Singing Bamboo Saffron Adventure Mountain Opulent Sunshine Adventure Elephant Mountain Adventure Dancing',37,9.25,5408,'Ezekiel Waylon','Elijah Theo','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Carnival Cascade','Twilight Reading Potion Adventure Swimming Symphony Singing Radiance Whimsical Aurora Dream Singing Thinking Tranquility Ocean Sunshine Potion Bicycle Singing Horizon Treasure Velvet Bicycle Firefly Harmony Firefly Starlight Ocean Dancing Rainbow Echo Mirage Bicycle Butterfly Trampoline Carnival Velvet Bamboo Zephyr Elephant',82,20.5,162,'Waylon Aurora','Evelyn Michael','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Trampoline Swimming','Thinking Cascade Whimsical Singing Carousel Enchantment Secret Dancing Carnival Serendipity Secret Bamboo Harmony Whimsical Singing Castle Dragon Bicycle Euphoria Treasure Lighthouse Serendipity Echo Opulent Elephant Velvet Harmony Sleeping Mystery Sleeping Velvet Galaxy Mystery Aurora Bicycle Dancing Mirage Velvet Opulent Dragon',75,67.5,824,'Ethan James','Mia Michael','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Bicycle Piano','Running Carousel Secret Mountain Chocolate Zephyr Mystery Dragon Opulent Enchantment Lighthouse Horizon Serenade Chocolate Whisper Writing Swimming Firefly Starlight Bicycle Apple Sunshine Treasure Cascade Adventure Horizon Firefly Running Whimsical Serenade Euphoria Secret Firefly Cascade Carnival Quicksilver Velvet Firefly Apple Chocolate',16,3.1999999999999993,6721,'Emma Nova','Madison Liam','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Rainbow Firefly','Mountain Horizon Ocean Writing Aurora Potion Euphoria Horizon Thinking Mountain Jumping Lighthouse Mystery Echo Piano Jumping Running Dragon Dragon Enchantment Lighthouse Thinking Tranquility Harmony Serendipity Serenade Running Cascade Velvet Jumping Treasure Swimming Trampoline Radiance Galaxy Firefly Echo Castle Enchantment Harmony',88,22.0,7778,'Eleanor Penelope','Aurora Grace','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Carousel Butterfly','Harmony Mountain Cascade Velvet Ocean Running Aurora Singing Aurora Treasure Bicycle Ocean Enchantment Thinking Telescope Saffron Butterfly Horizon Saffron Jumping Mirage Eating Apple Velvet Butterfly Apple Velvet Velvet Running Swimming Bamboo Horizon Mirage Firefly Lighthouse Sleeping Butterfly Writing Dream Serendipity',79,59.25,3641,'Samuel Emilia','Mila Emma','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Harmony Euphoria','Castle Starlight Dragon Galaxy Bicycle Serendipity Bicycle Horizon Mirage Treasure Castle Sunshine Jumping Thinking Twilight Sunshine Telescope Bamboo Opulent Serenade Aurora Aurora Sleeping Whimsical Jumping Radiance Sleeping Carnival Whisper Whisper Aurora Enchantment Mountain Saffron Sleeping Jumping Potion Whimsical Dream Castle',12,6.0,1921,'Isaiah Levi','Harper Sofia','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Euphoria Whimsical','Bicycle Thinking Butterfly Singing Sunshine Bamboo Opulent Tranquility Dream Apple Velvet Galaxy Adventure Sunshine Potion Enchantment Piano Carnival Moonlight Mystery Reading Dream Quicksilver Radiance Whisper Chocolate Horizon Echo Jumping Harmony Symphony Potion Horizon Saffron Euphoria Euphoria Whimsical Thinking Whimsical Ocean',60,30.0,2369,'Chloe Mason','Paisley David','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Rainbow Zephyr','Adventure Velvet Jumping Tranquility Serendipity Mystery Tranquility Trampoline Reading Starlight Serenade Running Mystery Chocolate Galaxy Tranquility Enchantment Euphoria Writing Writing Running Moonlight Writing Treasure Sunshine Harmony Twilight Singing Sleeping Dream Whisper Dream Mystery Horizon Horizon Mirage Whimsical Saffron Starlight Sunshine',80,16.0,4175,'Wyatt Ezra','Isabella Miles','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Moonlight Rainbow','Mountain Starlight Thinking Moonlight Whisper Starlight Dragon Mystery Saffron Treasure Dragon Mirage Bicycle Writing Symphony Carnival Firefly Moonlight Enchantment Thinking Eating Velvet Mountain Echo Reading Singing Adventure Velvet Zephyr Secret Elephant Carnival Dream Thinking Telescope Secret Running Zephyr Whisper Enchantment',35,28.0,9675,'Leo Harper','Hudson Lily','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Velvet Apple','Reading Velvet Singing Apple Dragon Thinking Castle Starlight Writing Treasure Potion Echo Rainbow Serenade Eating Lighthouse Velvet Swimming Moonlight Cascade Whimsical Lighthouse Piano Opulent Running Horizon Sunshine Secret Whimsical Sleeping Dragon Bamboo Opulent Serenade Horizon Trampoline Running Harmony Whimsical Starlight',35,28.0,2693,'Lily Luca','Riley Santiago','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Mystery Starlight','Running Piano Saffron Apple Dragon Chocolate Euphoria Dancing Horizon Ocean Tranquility Eating Radiance Serendipity Castle Carousel Mirage Lighthouse Dream Carnival Castle Secret Mystery Castle Dream Serenade Dancing Velvet Echo Aurora Sunshine Enchantment Twilight Opulent Mountain Mystery Ocean Adventure Singing Whimsical',14,2.799999999999999,4037,'Elizabeth Asher','Avery Julian','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Enchantment Firefly','Echo Running Bamboo Whimsical Tranquility Mirage Lighthouse Whimsical Whisper Firefly Firefly Quicksilver Castle Sleeping Bicycle Firefly Castle Piano Secret Eating Rainbow Elephant Eating Galaxy Mirage Twilight Twilight Adventure Mountain Rainbow Ocean Running Castle Moonlight Dancing Twilight Zephyr Writing Adventure Apple',81,60.75,5411,'Willow Nova','Daniel Ellie','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Mystery Cascade','Harmony Dragon Velvet Elephant Castle Chocolate Ocean Potion Velvet Zephyr Firefly Rainbow Carnival Harmony Sleeping Mirage Twilight Firefly Velvet Opulent Enchantment Sleeping Symphony Swimming Butterfly Whimsical Carnival Dream Dancing Whisper Thinking Singing Velvet Singing Euphoria Singing Cascade Secret Opulent Secret',13,2.5999999999999996,8904,'Henry Eliana','Gianna Avery','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Twilight Reading','Enchantment Galaxy Secret Carousel Telescope Harmony Serenade Ocean Serendipity Carousel Chocolate Velvet Rainbow Jumping Treasure Castle Piano Castle Eating Sunshine Velvet Dragon Serenade Harmony Serenade Telescope Euphoria Piano Apple Swimming Zephyr Jumping Serendipity Bamboo Enchantment Serenade Moonlight Opulent Bamboo Piano',8,2.0,4700,'Miles Josiah','Asher Henry','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Ocean Piano','Starlight Sleeping Lighthouse Piano Reading Reading Starlight Dragon Quicksilver Mirage Zephyr Sleeping Butterfly Galaxy Moonlight Echo Eating Euphoria Bamboo Serendipity Elephant Thinking Velvet Moonlight Galaxy Rainbow Zephyr Cascade Potion Velvet Horizon Carnival Elephant Castle Writing Ocean Carousel Enchantment Serenade Mirage',76,38.0,7446,'Waylon Luca','Ezra Theodore','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Castle Tranquility','Harmony Dancing Ocean Eating Adventure Trampoline Chocolate Chocolate Singing Elephant Galaxy Serenade Whimsical Treasure Ocean Ocean Aurora Serenade Whimsical Elephant Rainbow Jumping Mirage Harmony Mountain Lighthouse Dream Cascade Elephant Twilight Dragon Piano Lighthouse Twilight Galaxy Dream Potion Carousel Starlight Tranquility',10,2.5,1436,'Emily Sophia','Luke Benjamin','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Reading Piano','Mystery Carnival Zephyr Mystery Lighthouse Enchantment Eating Bamboo Running Writing Mirage Euphoria Dancing Twilight Radiance Secret Aurora Telescope Chocolate Dragon Galaxy Cascade Serenade Eating Bicycle Serenade Velvet Secret Eating Opulent Sunshine Radiance Aurora Potion Symphony Chocolate Castle Aurora Radiance Dancing',42,16.8,3296,'Matthew Luca','Carter Jayden','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Carousel Firefly','Elephant Serendipity Dragon Carnival Writing Moonlight Lighthouse Serenade Opulent Reading Piano Horizon Ocean Singing Bicycle Symphony Telescope Carnival Running Adventure Harmony Opulent Rainbow Zephyr Eating Potion Whisper Sleeping Cascade Bicycle Bicycle Dream Apple Running Reading Serendipity Mystery Jumping Zephyr Velvet',68,27.200000000000003,6430,'Samuel Maverick','Emilia Gianna','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Whisper Bamboo','Bicycle Dream Enchantment Whisper Adventure Mountain Singing Dancing Adventure Serendipity Piano Opulent Carousel Elephant Harmony Butterfly Bamboo Echo Bicycle Bicycle Trampoline Carousel Quicksilver Singing Aurora Whisper Velvet Bamboo Aurora Bamboo Ocean Telescope Galaxy Serenade Velvet Starlight Butterfly Lighthouse Butterfly Radiance',75,75,4336,'Eleanor Michael','Jacob Ezekiel','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mountain Dancing Mountain','Telescope Butterfly Telescope Serenade Opulent Dragon Telescope Running Thinking Radiance Harmony Mystery Secret Dancing Euphoria Twilight Eating Bamboo Aurora Lighthouse Serenade Mountain Rainbow Aurora Quicksilver Starlight Starlight Mirage Jumping Treasure Opulent Secret Carnival Carnival Mystery Running Swimming Chocolate Saffron Mystery',44,11.0,6119,'James Avery','Leo Luke','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Twilight Tranquility','Sleeping Aurora Serendipity Mountain Quicksilver Castle Sunshine Butterfly Quicksilver Velvet Castle Adventure Horizon Secret Tranquility Treasure Firefly Trampoline Carnival Mirage Jumping Eating Lighthouse Adventure Harmony Mountain Ocean Chocolate Rainbow Quicksilver Apple Jumping Serendipity Thinking Bamboo Harmony Harmony Jumping Running Treasure',71,71,9669,'Harper Luke','Athena Leilani','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Radiance Piano','Eating Dragon Bamboo Mirage Twilight Twilight Echo Velvet Piano Starlight Lighthouse Euphoria Velvet Whisper Swimming Serendipity Ocean Velvet Eating Telescope Dragon Jumping Bicycle Elephant Secret Serenade Chocolate Swimming Moonlight Velvet Mountain Velvet Quicksilver Thinking Whimsical Serendipity Potion Harmony Euphoria Chocolate',45,9.0,1358,'Levi Sofia','Santiago Benjamin','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Whisper Enchantment','Radiance Bamboo Carousel Bamboo Quicksilver Apple Euphoria Enchantment Trampoline Potion Reading Whisper Cascade Thinking Sleeping Swimming Horizon Apple Galaxy Aurora Serenade Treasure Aurora Chocolate Whisper Eating Telescope Saffron Bamboo Jumping Echo Zephyr Moonlight Apple Dragon Starlight Ocean Writing Sunshine Euphoria',39,9.75,6344,'Julian Ava','Alexander Aurora','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Singing Rainbow','Apple Serenade Opulent Writing Saffron Echo Chocolate Eating Potion Firefly Echo Harmony Opulent Echo Singing Apple Twilight Twilight Treasure Quicksilver Sunshine Dragon Serenade Treasure Echo Lighthouse Lighthouse Ocean Saffron Zephyr Harmony Serenade Treasure Running Mountain Whimsical Carousel Cascade Enchantment Jumping',20,20,4138,'William Nova','Aiden Sophia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Mountain Carousel','Dancing Aurora Twilight Firefly Mystery Serenade Rainbow Trampoline Starlight Eating Bicycle Opulent Secret Sunshine Elephant Chocolate Whimsical Sleeping Trampoline Carousel Castle Butterfly Twilight Mirage Treasure Reading Butterfly Harmony Dancing Trampoline Butterfly Opulent Bicycle Sunshine Castle Reading Firefly Aurora Zephyr Velvet',95,47.5,4191,'Aria Emma','Mia Evelyn','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Piano Symphony','Telescope Whisper Bamboo Thinking Whisper Twilight Eating Enchantment Tranquility Moonlight Elephant Treasure Twilight Dancing Sunshine Serenade Bamboo Quicksilver Telescope Serenade Bicycle Echo Butterfly Euphoria Firefly Rainbow Moonlight Eating Eating Tranquility Sunshine Twilight Treasure Harmony Symphony Harmony Tranquility Running Sunshine Butterfly',65,52.0,8274,'Jack Delilah','Lucas Luca','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Secret Potion','Echo Butterfly Galaxy Castle Serenade Running Carousel Tranquility Starlight Dancing Serendipity Writing Lighthouse Apple Jumping Dancing Eating Rainbow Twilight Dream Swimming Opulent Radiance Ocean Cascade Dragon Potion Potion Lighthouse Enchantment Secret Thinking Running Adventure Mountain Echo Starlight Starlight Carnival Apple',97,38.800000000000004,1110,'Aria Naomi','Theo Muhammad','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Velvet Opulent','Bicycle Twilight Radiance Potion Tranquility Mirage Starlight Starlight Cascade Radiance Aurora Saffron Swimming Dancing Dragon Aurora Harmony Potion Serendipity Mountain Serenade Piano Sunshine Secret Ocean Castle Harmony Carnival Chocolate Cascade Dream Velvet Mirage Harmony Velvet Enchantment Velvet Jumping Harmony Enchantment',30,27.0,2699,'Harper Amelia','Naomi Jacob','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Castle Writing','Echo Enchantment Rainbow Bamboo Sunshine Carousel Velvet Echo Horizon Quicksilver Sunshine Aurora Potion Velvet Writing Singing Singing Lighthouse Bicycle Enchantment Horizon Treasure Piano Saffron Bicycle Trampoline Symphony Quicksilver Sunshine Telescope Zephyr Quicksilver Carousel Carousel Trampoline Bicycle Butterfly Sleeping Potion Dragon',26,5.199999999999999,7505,'Theodore Hudson','Santiago Mia','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Apple Rainbow','Telescope Velvet Mountain Writing Lighthouse Euphoria Sleeping Elephant Whimsical Running Tranquility Telescope Butterfly Twilight Velvet Harmony Castle Velvet Enchantment Horizon Symphony Whimsical Mirage Moonlight Euphoria Quicksilver Tranquility Velvet Piano Sunshine Enchantment Firefly Velvet Running Starlight Carnival Telescope Rainbow Dream Bicycle',88,22.0,4506,'Henry Josiah','Grace Michael','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Radiance Rainbow','Elephant Serenade Butterfly Eating Starlight Reading Bicycle Jumping Rainbow Serenade Jumping Bicycle Echo Whimsical Serendipity Zephyr Sleeping Adventure Eating Eating Bicycle Serendipity Chocolate Opulent Sunshine Potion Chocolate Elephant Twilight Galaxy Firefly Sleeping Telescope Bamboo Treasure Twilight Mountain Butterfly Euphoria Velvet',26,19.5,3974,'Noah Maya','Paisley Matthew','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Eating Radiance','Piano Aurora Serendipity Opulent Chocolate Galaxy Running Reading Treasure Bicycle Euphoria Euphoria Zephyr Castle Opulent Chocolate Velvet Telescope Harmony Sunshine Potion Mystery Enchantment Secret Serendipity Swimming Dream Serendipity Singing Cascade Galaxy Horizon Telescope Telescope Potion Mystery Harmony Jumping Dream Mountain',2,1.0,6393,'Amelia Theo','Michael Luca','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Saffron Whisper','Potion Running Running Mountain Serenade Adventure Starlight Serenade Quicksilver Galaxy Adventure Starlight Castle Apple Symphony Swimming Whimsical Running Horizon Rainbow Euphoria Velvet Sunshine Ocean Telescope Moonlight Butterfly Symphony Firefly Saffron Euphoria Horizon Firefly Euphoria Singing Galaxy Whimsical Symphony Cascade Velvet',68,68,3956,'Elena Naomi','James Avery','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Carousel Piano','Saffron Lighthouse Euphoria Opulent Chocolate Trampoline Singing Quicksilver Saffron Radiance Adventure Dream Aurora Potion Enchantment Swimming Quicksilver Bamboo Trampoline Telescope Jumping Enchantment Treasure Aurora Secret Serendipity Mystery Mountain Galaxy Apple Enchantment Velvet Trampoline Dancing Mirage Elephant Cascade Velvet Serendipity Velvet',5,4.0,566,'Lucas Muhammad','Charlotte Gabriel','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Radiance Enchantment Bicycle','Dream Galaxy Secret Moonlight Velvet Twilight Writing Whisper Singing Dancing Echo Starlight Sleeping Opulent Piano Dancing Moonlight Echo Treasure Chocolate Tranquility Running Telescope Singing Piano Mystery Singing Bicycle Velvet Echo Jumping Carnival Velvet Dragon Thinking Radiance Running Saffron Elephant Carnival',95,85.5,8006,'Elias Michael','Gabriel Jacob','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Saffron Elephant','Firefly Dragon Twilight Quicksilver Whimsical Writing Apple Whisper Ocean Whisper Butterfly Cascade Galaxy Carnival Serenade Writing Eating Butterfly Potion Reading Chocolate Velvet Thinking Lighthouse Apple Symphony Zephyr Treasure Mountain Mystery Writing Carnival Aurora Horizon Eating Moonlight Jumping Swimming Dream Carnival',75,67.5,3444,'Levi Julian','Leo Noah','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Tranquility Serendipity','Enchantment Eating Harmony Echo Elephant Running Velvet Dancing Swimming Apple Bicycle Reading Echo Whimsical Harmony Telescope Swimming Moonlight Thinking Elephant Trampoline Trampoline Saffron Whisper Euphoria Castle Telescope Apple Velvet Piano Symphony Echo Potion Writing Horizon Horizon Ocean Dancing Rainbow Thinking',6,6,2960,'Ava Jacob','Riley William','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Horizon Whisper','Mountain Mystery Euphoria Jumping Starlight Castle Jumping Horizon Firefly Saffron Thinking Dream Velvet Zephyr Secret Trampoline Sunshine Piano Mirage Piano Sunshine Potion Aurora Elephant Dancing Lighthouse Telescope Serendipity Saffron Ocean Bamboo Euphoria Butterfly Telescope Radiance Horizon Telescope Velvet Enchantment Horizon',19,3.799999999999999,253,'Grayson Sofia','Aiden Muhammad','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Velvet Starlight','Radiance Reading Galaxy Bicycle Opulent Velvet Dream Galaxy Eating Bamboo Firefly Eating Trampoline Serendipity Quicksilver Carnival Radiance Trampoline Castle Potion Serendipity Serendipity Zephyr Running Chocolate Running Velvet Ocean Serenade Echo Sunshine Sleeping Mountain Trampoline Whisper Elephant Carnival Dancing Zephyr Firefly',87,17.39999999999999,6492,'Violet Theo','Sofia Theo','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Piano Aurora','Sunshine Adventure Bamboo Opulent Running Jumping Potion Jumping Firefly Serendipity Chocolate Sunshine Carnival Secret Carnival Bicycle Quicksilver Tranquility Enchantment Elephant Carousel Bamboo Mystery Symphony Harmony Euphoria Chocolate Aurora Horizon Trampoline Starlight Trampoline Enchantment Writing Trampoline Euphoria Dream Apple Enchantment Symphony',52,52,5697,'Isabella Gabriel','Gabriel Asher','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Piano Dream','Radiance Tranquility Mirage Sunshine Carnival Jumping Dream Castle Horizon Bicycle Aurora Firefly Velvet Mystery Galaxy Galaxy Apple Starlight Serendipity Zephyr Echo Reading Firefly Velvet Firefly Quicksilver Reading Whimsical Telescope Whimsical Elephant Bicycle Serenade Telescope Twilight Galaxy Treasure Galaxy Serendipity Sleeping',47,23.5,2984,'Wyatt Theodore','Hazel Isabella','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Symphony Bamboo','Horizon Radiance Thinking Cascade Serendipity Dream Telescope Rainbow Potion Trampoline Tranquility Adventure Eating Potion Potion Rainbow Moonlight Quicksilver Chocolate Tranquility Tranquility Eating Whimsical Moonlight Piano Symphony Carnival Lighthouse Jumping Euphoria Saffron Apple Singing Starlight Serenade Telescope Mirage Galaxy Velvet Potion',61,48.8,6672,'Nora Carter','Delilah Ella','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Telescope Butterfly Quicksilver','Twilight Apple Zephyr Reading Serenade Tranquility Bicycle Elephant Running Potion Velvet Horizon Moonlight Eating Singing Velvet Trampoline Horizon Running Dancing Swimming Castle Secret Piano Dragon Potion Dancing Starlight Eating Mirage Dragon Bicycle Serenade Jumping Velvet Running Writing Harmony Aurora Serenade',66,13.199999999999996,6767,'Julian Violet','Elena Naomi','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Rainbow Saffron','Castle Whimsical Serenade Chocolate Adventure Adventure Rainbow Lighthouse Saffron Symphony Carnival Ocean Saffron Velvet Singing Dream Opulent Bamboo Singing Dancing Lighthouse Mountain Cascade Potion Dancing Whisper Echo Secret Firefly Lighthouse Zephyr Bamboo Rainbow Moonlight Opulent Bicycle Whimsical Dancing Apple Potion',27,21.6,4974,'Ellie Sophia','Benjamin Sofia','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Moonlight Mirage','Eating Quicksilver Saffron Potion Twilight Elephant Rainbow Apple Piano Potion Adventure Ocean Mystery Reading Aurora Chocolate Lighthouse Mystery Horizon Firefly Galaxy Rainbow Symphony Adventure Mountain Velvet Mirage Tranquility Castle Serendipity Whimsical Galaxy Writing Adventure Firefly Quicksilver Treasure Sleeping Whisper Harmony',63,50.4,7762,'Elena Hazel','Willow Amelia','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Carnival Butterfly','Galaxy Aurora Galaxy Lighthouse Tranquility Galaxy Reading Mountain Enchantment Telescope Horizon Jumping Velvet Piano Saffron Euphoria Chocolate Mystery Bamboo Apple Saffron Telescope Moonlight Quicksilver Running Secret Thinking Opulent Reading Dragon Starlight Galaxy Opulent Cascade Quicksilver Twilight Butterfly Dancing Aurora Mystery',85,63.75,1971,'Eliana Avery','Luna Emilia','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Serendipity Velvet','Telescope Twilight Quicksilver Horizon Adventure Secret Horizon Castle Serenade Eating Echo Velvet Serendipity Harmony Sunshine Carousel Tranquility Eating Bamboo Sunshine Dragon Bicycle Carnival Swimming Symphony Secret Mirage Trampoline Echo Dream Quicksilver Lighthouse Velvet Dancing Mountain Elephant Dancing Echo Twilight Harmony',21,5.25,6448,'Noah Muhammad','Luna Violet','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Horizon Dragon','Harmony Moonlight Telescope Symphony Carousel Bicycle Saffron Serenade Carousel Carnival Sleeping Jumping Swimming Moonlight Opulent Moonlight Symphony Adventure Mountain Tranquility Echo Reading Lighthouse Zephyr Eating Mirage Bicycle Radiance Dancing Tranquility Thinking Aurora Apple Swimming Mirage Thinking Singing Sunshine Moonlight Running',25,25,6727,'Emma Daniel','Isabella Logan','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Bamboo Tranquility','Whimsical Carousel Mountain Enchantment Moonlight Castle Thinking Twilight Mountain Saffron Sunshine Dancing Running Moonlight Lighthouse Quicksilver Dream Mystery Trampoline Swimming Rainbow Carnival Elephant Harmony Tranquility Starlight Harmony Horizon Zephyr Euphoria Chocolate Velvet Dragon Treasure Sunshine Opulent Swimming Piano Butterfly Eating',37,14.8,8218,'Abigail Aurora','Alexander David','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Radiance Piano Harmony','Eating Enchantment Mountain Mystery Elephant Whisper Serenade Firefly Bamboo Whimsical Mystery Serenade Dream Opulent Opulent Euphoria Castle Reading Eating Sunshine Ocean Writing Bamboo Enchantment Apple Whimsical Jumping Sunshine Piano Elephant Bamboo Telescope Bamboo Galaxy Starlight Bicycle Elephant Sunshine Reading Ocean',50,40.0,7313,'Logan Hazel','Luke Aiden','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Mystery Butterfly','Whimsical Castle Elephant Whisper Quicksilver Castle Opulent Dancing Tranquility Writing Chocolate Aurora Sleeping Carousel Twilight Velvet Ocean Reading Jumping Singing Carnival Carousel Running Telescope Zephyr Eating Castle Echo Lighthouse Castle Swimming Eating Cascade Sunshine Serenade Rainbow Bicycle Castle Serenade Whimsical',41,8.199999999999996,7991,'Waylon Zoey','Theodore Emilia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Dream Serendipity','Lighthouse Carnival Horizon Saffron Cascade Castle Lighthouse Sleeping Writing Whisper Velvet Ocean Elephant Moonlight Dragon Galaxy Thinking Chocolate Running Running Dancing Sunshine Secret Aurora Chocolate Dream Horizon Castle Chocolate Telescope Twilight Adventure Carnival Swimming Whisper Opulent Rainbow Sleeping Horizon Cascade',10,9.0,4384,'Hazel Aurora','Amelia Luke','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Apple Running','Castle Horizon Mirage Bicycle Serendipity Piano Carnival Thinking Mystery Tranquility Bicycle Carnival Carousel Lighthouse Velvet Opulent Bicycle Quicksilver Euphoria Eating Dream Velvet Running Bamboo Reading Sleeping Symphony Saffron Thinking Cascade Castle Symphony Harmony Velvet Bamboo Whimsical Dragon Swimming Horizon Dragon',46,41.4,491,'Kai Isaiah','Owen James','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Piano Eating','Aurora Swimming Radiance Horizon Elephant Tranquility Velvet Singing Bicycle Rainbow Horizon Sunshine Apple Galaxy Mountain Echo Firefly Cascade Serenade Starlight Reading Piano Galaxy Velvet Castle Symphony Bicycle Thinking Sleeping Lighthouse Secret Whisper Lighthouse Opulent Firefly Apple Quicksilver Starlight Writing Opulent',80,16.0,627,'Luna Grayson','Aiden Harper','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Adventure Dream','Thinking Dancing Moonlight Ocean Symphony Singing Mountain Rainbow Eating Euphoria Whimsical Harmony Opulent Harmony Cascade Dancing Twilight Tranquility Sleeping Jumping Opulent Serendipity Velvet Sunshine Sleeping Telescope Mystery Reading Piano Elephant Dancing Enchantment Cascade Twilight Swimming Starlight Dream Treasure Dancing Treasure',19,3.799999999999999,1549,'Santiago Santiago','Elijah Samuel','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Starlight Bicycle','Swimming Thinking Serendipity Moonlight Echo Treasure Aurora Serenade Zephyr Dream Galaxy Serenade Writing Saffron Swimming Dream Cascade Radiance Twilight Adventure Singing Reading Saffron Running Mountain Horizon Chocolate Butterfly Aurora Trampoline Secret Butterfly Velvet Castle Elephant Bamboo Jumping Dragon Adventure Dream',15,12.0,6102,'Santiago Leilani','Isla Gianna','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Velvet Trampoline','Galaxy Dream Dancing Writing Mirage Bicycle Twilight Starlight Zephyr Potion Bicycle Opulent Firefly Jumping Starlight Singing Aurora Elephant Serendipity Butterfly Writing Dream Euphoria Sunshine Lighthouse Cascade Writing Castle Serendipity Mystery Reading Harmony Saffron Writing Firefly Secret Ocean Zephyr Twilight Butterfly',94,37.6,6030,'Lily Zoey','Logan William','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Echo Symphony Writing','Galaxy Galaxy Firefly Harmony Singing Cascade Writing Writing Bamboo Swimming Mirage Thinking Mystery Reading Euphoria Telescope Reading Elephant Moonlight Radiance Moonlight Apple Rainbow Euphoria Elephant Sleeping Velvet Piano Enchantment Opulent Potion Bamboo Opulent Velvet Moonlight Ocean Singing Serenade Aurora Dancing',29,23.2,2553,'Theo Sebastian','Gianna Ethan','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Horizon Twilight','Firefly Dream Bamboo Chocolate Zephyr Carousel Whisper Whisper Quicksilver Apple Horizon Running Bicycle Zephyr Moonlight Elephant Velvet Writing Adventure Dragon Serenade Dragon Adventure Twilight Adventure Singing Tranquility Sleeping Elephant Dragon Radiance Sunshine Mirage Piano Whisper Trampoline Adventure Galaxy Ocean Enchantment',88,79.2,5417,'Delilah Theodore','Lily Sofia','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Whisper Echo','Radiance Velvet Thinking Trampoline Enchantment Whisper Writing Moonlight Carnival Galaxy Running Galaxy Starlight Elephant Whisper Dream Velvet Opulent Running Swimming Secret Lighthouse Serenade Whisper Telescope Tranquility Horizon Swimming Sleeping Moonlight Thinking Dream Telescope Bamboo Butterfly Lighthouse Castle Running Cascade Symphony',83,41.5,1309,'Emilia Naomi','Muhammad Matthew','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mountain Running Harmony','Reading Rainbow Secret Enchantment Jumping Serenade Carousel Enchantment Treasure Chocolate Writing Potion Echo Echo Saffron Velvet Apple Dragon Euphoria Mountain Firefly Butterfly Twilight Twilight Rainbow Echo Swimming Galaxy Quicksilver Chocolate Serendipity Enchantment Bamboo Thinking Dragon Writing Rainbow Saffron Harmony Castle',99,24.75,6243,'Matthew Samuel','Ellie Zoe','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Tranquility Reading','Carousel Ocean Dream Piano Reading Whimsical Harmony Elephant Reading Quicksilver Butterfly Serenade Bamboo Euphoria Whimsical Velvet Dancing Starlight Twilight Serendipity Apple Velvet Reading Cascade Trampoline Elephant Elephant Bicycle Sunshine Potion Cascade Opulent Sunshine Whimsical Reading Adventure Dream Firefly Jumping Sleeping',40,32.0,3345,'Elijah Nora','Luna Luke','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Harmony Writing','Euphoria Enchantment Starlight Whisper Rainbow Telescope Starlight Whimsical Piano Starlight Tranquility Galaxy Harmony Singing Horizon Secret Echo Rainbow Whimsical Apple Dancing Symphony Dream Tranquility Reading Chocolate Piano Piano Whisper Velvet Swimming Mystery Apple Elephant Apple Galaxy Serenade Jumping Serendipity Dancing',12,10.8,5571,'Violet Aria','Grayson Michael','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Rainbow Dream','Swimming Dream Sunshine Mystery Jumping Sunshine Galaxy Thinking Bamboo Chocolate Cascade Swimming Quicksilver Horizon Thinking Sleeping Telescope Trampoline Lighthouse Serendipity Rainbow Sleeping Tranquility Treasure Echo Jumping Bamboo Radiance Lighthouse Reading Velvet Sunshine Bamboo Horizon Sleeping Mystery Tranquility Butterfly Adventure Rainbow',92,82.8,2693,'Ezra Santiago','Asher Aurora','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Whisper Galaxy','Euphoria Adventure Eating Butterfly Euphoria Velvet Chocolate Harmony Sunshine Echo Dream Horizon Starlight Piano Symphony Writing Thinking Echo Eating Whisper Whisper Harmony Whisper Castle Euphoria Jumping Mirage Moonlight Mystery Carousel Castle Thinking Horizon Carnival Mountain Carousel Enchantment Rainbow Moonlight Dragon',22,5.5,7784,'Hudson Grayson','Muhammad Elizabeth','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Zephyr Swimming','Writing Rainbow Secret Singing Adventure Horizon Dancing Tranquility Bicycle Carousel Whimsical Lighthouse Jumping Dragon Whisper Tranquility Piano Adventure Elephant Carnival Singing Reading Elephant Serenade Singing Tranquility Trampoline Thinking Castle Firefly Singing Velvet Elephant Sleeping Whimsical Swimming Carnival Eating Telescope Mystery',76,15.199999999999996,3811,'Elijah Gianna','Isaiah Mason','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Echo Velvet','Starlight Secret Harmony Potion Echo Symphony Opulent Opulent Whisper Potion Ocean Zephyr Swimming Dancing Echo Carousel Enchantment Dream Apple Adventure Jumping Butterfly Dream Apple Trampoline Starlight Twilight Twilight Lighthouse Thinking Bamboo Opulent Bicycle Dream Firefly Piano Dream Elephant Harmony Secret',26,19.5,5410,'Levi Hudson','Mia Ezra','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Symphony Telescope','Mirage Serendipity Mystery Mirage Echo Swimming Zephyr Mountain Moonlight Tranquility Secret Enchantment Tranquility Castle Jumping Eating Singing Serendipity Moonlight Whisper Horizon Piano Euphoria Whimsical Telescope Horizon Symphony Treasure Castle Butterfly Tranquility Singing Saffron Quicksilver Symphony Cascade Bamboo Dragon Mystery Thinking',19,4.75,8277,'Olivia Theo','Elizabeth Leo','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Velvet Telescope','Serendipity Mystery Jumping Trampoline Swimming Secret Cascade Sunshine Galaxy Trampoline Serenade Lighthouse Opulent Moonlight Saffron Jumping Saffron Euphoria Velvet Carousel Symphony Adventure Running Quicksilver Velvet Euphoria Sunshine Dream Thinking Galaxy Firefly Chocolate Running Whimsical Dancing Mystery Tranquility Radiance Bamboo Zephyr',62,55.8,4947,'Ivy Charlotte','Olivia Maverick','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Dancing Reading','Echo Butterfly Butterfly Symphony Radiance Carnival Quicksilver Thinking Whimsical Treasure Serenade Eating Aurora Secret Twilight Lighthouse Horizon Moonlight Dream Twilight Lighthouse Serendipity Ocean Bicycle Apple Apple Whisper Trampoline Adventure Horizon Whisper Opulent Horizon Reading Apple Eating Dancing Dream Serenade Piano',43,8.600000000000001,989,'Hazel Maverick','Eleanor Riley','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Euphoria Galaxy','Apple Moonlight Mirage Saffron Zephyr Horizon Carousel Singing Mountain Sunshine Radiance Chocolate Dancing Writing Jumping Ocean Harmony Zephyr Trampoline Moonlight Lighthouse Swimming Galaxy Elephant Euphoria Moonlight Quicksilver Bamboo Running Piano Serendipity Euphoria Zephyr Writing Aurora Harmony Whimsical Thinking Running Rainbow',90,67.5,9904,'Elias Ivy','Samuel Jack','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Mountain Carousel','Jumping Running Treasure Velvet Thinking Dream Quicksilver Swimming Carousel Ocean Treasure Writing Butterfly Velvet Eating Aurora Mirage Radiance Whisper Whimsical Mirage Velvet Jumping Galaxy Opulent Rainbow Whisper Castle Galaxy Echo Butterfly Opulent Saffron Velvet Quicksilver Potion Apple Aurora Singing Velvet',21,18.9,2227,'Ella Sophia','Elizabeth Riley','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Opulent Sleeping Sleeping','Treasure Cascade Lighthouse Reading Enchantment Serenade Serenade Mirage Radiance Euphoria Adventure Singing Castle Symphony Sunshine Adventure Thinking Quicksilver Chocolate Eating Chocolate Jumping Horizon Singing Trampoline Mirage Treasure Euphoria Twilight Serenade Whisper Apple Lighthouse Sleeping Aurora Writing Secret Quicksilver Dragon Eating',1,0.4,8007,'Luke Muhammad','Alexander Jackson','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Tranquility Sleeping','Velvet Running Singing Elephant Butterfly Quicksilver Bamboo Velvet Tranquility Rainbow Dancing Sunshine Butterfly Reading Moonlight Sunshine Galaxy Galaxy Ocean Carousel Starlight Opulent Zephyr Velvet Rainbow Bamboo Opulent Aurora Castle Whisper Velvet Velvet Zephyr Galaxy Ocean Quicksilver Mystery Echo Radiance Writing',99,49.5,4314,'Riley Kai','Abigail Michael','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Castle Running','Opulent Elephant Symphony Reading Twilight Elephant Moonlight Aurora Swimming Bicycle Cascade Reading Tranquility Bicycle Secret Rainbow Quicksilver Twilight Mirage Potion Secret Aurora Rainbow Sleeping Echo Secret Swimming Ocean Whimsical Echo Aurora Mirage Dancing Jumping Elephant Firefly Singing Harmony Telescope Zephyr',54,10.799999999999997,4622,'Henry Ava','Mia Isaiah','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Serendipity Mystery','Dream Radiance Sleeping Velvet Bamboo Dream Bicycle Reading Serendipity Sleeping Harmony Mountain Mirage Rainbow Lighthouse Harmony Symphony Lighthouse Chocolate Quicksilver Swimming Telescope Euphoria Cascade Lighthouse Piano Cascade Galaxy Running Secret Quicksilver Telescope Dragon Starlight Elephant Moonlight Sleeping Cascade Opulent Treasure',19,4.75,7595,'Paisley Isaiah','Willow Henry','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Dream Opulent','Castle Dragon Euphoria Whimsical Mystery Bamboo Harmony Quicksilver Sleeping Radiance Bamboo Running Sunshine Jumping Elephant Trampoline Whisper Serendipity Piano Piano Sunshine Eating Radiance Whimsical Bicycle Mountain Enchantment Singing Quicksilver Dragon Jumping Ocean Velvet Harmony Tranquility Harmony Sunshine Swimming Twilight Saffron',93,74.4,5052,'Maverick Nova','Ezra Hudson','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Trampoline Enchantment','Piano Opulent Symphony Harmony Lighthouse Serendipity Dragon Dancing Twilight Euphoria Writing Apple Twilight Horizon Potion Secret Treasure Trampoline Bicycle Mirage Carnival Dancing Euphoria Cascade Serenade Mountain Carousel Harmony Trampoline Elephant Adventure Zephyr Radiance Cascade Bicycle Sunshine Opulent Singing Saffron Tranquility',40,16.0,5682,'Isla Carter','Avery Waylon','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Euphoria Castle','Carnival Chocolate Piano Quicksilver Adventure Moonlight Apple Elephant Rainbow Moonlight Ocean Serendipity Starlight Trampoline Dream Radiance Euphoria Serenade Cascade Aurora Twilight Carnival Apple Ocean Treasure Jumping Bicycle Elephant Elephant Dream Running Jumping Dream Thinking Sleeping Swimming Piano Aurora Quicksilver Telescope',48,48,3768,'Isla Elizabeth','Mateo Layla','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bamboo Rainbow Opulent','Thinking Mountain Rainbow Zephyr Running Starlight Quicksilver Serendipity Velvet Opulent Enchantment Carnival Firefly Castle Opulent Saffron Quicksilver Secret Serenade Apple Opulent Galaxy Mystery Velvet Velvet Moonlight Horizon Velvet Whimsical Elephant Dancing Euphoria Zephyr Ocean Butterfly Bicycle Dream Starlight Bicycle Lighthouse',12,9.6,4045,'Mateo Aurora','Elias Olivia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Galaxy Writing','Dragon Ocean Moonlight Chocolate Enchantment Butterfly Lighthouse Mountain Secret Secret Echo Galaxy Jumping Harmony Thinking Velvet Cascade Radiance Whimsical Elephant Elephant Sunshine Rainbow Firefly Secret Harmony Tranquility Firefly Potion Sleeping Chocolate Thinking Harmony Opulent Treasure Aurora Elephant Mountain Chocolate Whisper',54,54,5607,'Penelope Luca','Theodore Asher','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Lighthouse Chocolate','Radiance Horizon Swimming Dancing Starlight Chocolate Serendipity Sunshine Treasure Reading Secret Tranquility Secret Dragon Radiance Thinking Bamboo Tranquility Galaxy Jumping Writing Moonlight Serenade Opulent Reading Saffron Horizon Whisper Moonlight Sleeping Serendipity Serendipity Velvet Bamboo Quicksilver Serendipity Bicycle Starlight Zephyr Castle',97,19.39999999999999,8321,'Abigail Willow','Kai Liam','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Firefly Radiance','Serenade Adventure Whisper Bamboo Galaxy Treasure Enchantment Dancing Ocean Thinking Carousel Dragon Running Rainbow Running Mountain Tranquility Rainbow Jumping Radiance Bicycle Sunshine Sunshine Lighthouse Enchantment Dream Singing Dancing Adventure Enchantment Treasure Secret Serenade Quicksilver Mystery Potion Butterfly Writing Writing Symphony',84,21.0,6850,'Athena Ethan','Nova Delilah','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Adventure Enchantment','Potion Serenade Enchantment Elephant Running Telescope Firefly Saffron Enchantment Mirage Writing Running Serendipity Serendipity Reading Twilight Aurora Firefly Harmony Quicksilver Harmony Enchantment Opulent Mountain Treasure Telescope Ocean Serenade Chocolate Bamboo Mountain Aurora Enchantment Moonlight Treasure Writing Lighthouse Radiance Chocolate Dream',70,70,5770,'James Riley','Oliver Amelia','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Butterfly Echo','Jumping Writing Mountain Treasure Adventure Sleeping Zephyr Singing Firefly Chocolate Secret Secret Castle Sleeping Bicycle Harmony Carousel Quicksilver Potion Telescope Trampoline Mirage Castle Serenade Euphoria Writing Starlight Galaxy Butterfly Thinking Eating Dragon Carnival Opulent Bicycle Harmony Twilight Harmony Writing Dancing',92,82.8,2376,'Elijah Ivy','Willow Penelope','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Ocean Lighthouse Moonlight','Symphony Ocean Thinking Serenade Echo Horizon Carousel Writing Eating Reading Dancing Whisper Saffron Echo Bicycle Secret Bicycle Moonlight Whimsical Enchantment Eating Running Butterfly Adventure Mirage Elephant Piano Adventure Symphony Jumping Writing Whimsical Ocean Enchantment Dancing Mountain Bicycle Velvet Horizon Harmony',22,19.8,2599,'Amelia Oliver','Gianna Hudson','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Whimsical Secret','Cascade Mountain Secret Jumping Reading Enchantment Singing Carnival Twilight Whisper Horizon Galaxy Firefly Whimsical Quicksilver Piano Treasure Aurora Opulent Piano Eating Moonlight Reading Carnival Aurora Dream Mountain Butterfly Reading Tranquility Twilight Secret Carousel Quicksilver Velvet Symphony Ocean Velvet Horizon Carousel',93,74.4,2356,'Naomi Theo','Ava Leilani','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Potion Zephyr','Velvet Rainbow Twilight Potion Thinking Chocolate Symphony Saffron Zephyr Mystery Potion Whisper Moonlight Velvet Piano Reading Secret Thinking Serendipity Mountain Elephant Potion Potion Velvet Singing Reading Castle Jumping Enchantment Elephant Cascade Jumping Swimming Galaxy Telescope Jumping Lighthouse Sunshine Mountain Apple',50,50,7871,'Lily Jayden','Lily David','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Carnival Singing','Mirage Cascade Adventure Jumping Saffron Whisper Whisper Serenade Twilight Sunshine Whisper Moonlight Writing Trampoline Serenade Serenade Serenade Dream Dancing Whimsical Serendipity Carousel Writing Dancing Rainbow Horizon Dancing Tranquility Apple Starlight Starlight Euphoria Cascade Telescope Dragon Whimsical Serenade Secret Serendipity Thinking',33,33,1644,'Avery Charlotte','Benjamin Daniel','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Serendipity Trampoline','Moonlight Apple Apple Swimming Jumping Enchantment Horizon Elephant Symphony Opulent Lighthouse Sunshine Lighthouse Serendipity Velvet Singing Rainbow Potion Saffron Velvet Twilight Trampoline Swimming Echo Thinking Harmony Serenade Dancing Adventure Aurora Butterfly Serenade Piano Elephant Chocolate Bamboo Sleeping Euphoria Moonlight Mystery',22,22,2945,'Maya Scarlett','Luna David','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Potion Twilight','Sleeping Cascade Castle Starlight Singing Adventure Adventure Velvet Zephyr Dancing Moonlight Firefly Enchantment Butterfly Mirage Firefly Symphony Dragon Dancing Velvet Firefly Sunshine Singing Telescope Butterfly Adventure Euphoria Twilight Galaxy Moonlight Running Horizon Quicksilver Serendipity Moonlight Symphony Twilight Eating Mystery Dancing',84,21.0,2450,'Ezekiel Matthew','Aurora Noah','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Sleeping Chocolate','Dream Horizon Thinking Opulent Quicksilver Adventure Sleeping Swimming Ocean Symphony Whisper Opulent Treasure Starlight Harmony Lighthouse Serendipity Elephant Sleeping Opulent Running Galaxy Mystery Sunshine Writing Whimsical Sleeping Dragon Mountain Whimsical Saffron Butterfly Apple Sleeping Horizon Running Rainbow Apple Whisper Enchantment',51,40.8,9411,'Samuel Isaiah','Ethan Hudson','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Starlight Tranquility','Running Galaxy Elephant Opulent Singing Treasure Dream Zephyr Treasure Treasure Firefly Euphoria Jumping Potion Butterfly Horizon Ocean Castle Lighthouse Moonlight Secret Castle Dragon Apple Piano Sleeping Rainbow Reading Mountain Eating Dancing Firefly Writing Reading Whisper Writing Thinking Radiance Apple Carousel',82,82,9270,'Olivia Violet','Avery Ella','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Castle Potion','Thinking Zephyr Whimsical Jumping Aurora Butterfly Euphoria Adventure Dream Cascade Mystery Sleeping Running Moonlight Ocean Moonlight Zephyr Symphony Elephant Dancing Dream Velvet Saffron Dancing Galaxy Treasure Ocean Piano Harmony Secret Trampoline Ocean Bamboo Eating Radiance Galaxy Elephant Moonlight Jumping Horizon',35,7.0,85,'Julian Liam','Ellie Charlotte','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dragon Carousel Telescope','Sunshine Twilight Saffron Apple Opulent Bamboo Enchantment Potion Rainbow Mountain Twilight Treasure Tranquility Sleeping Enchantment Mystery Elephant Mirage Twilight Butterfly Enchantment Treasure Piano Chocolate Chocolate Writing Sleeping Serenade Twilight Mystery Ocean Galaxy Jumping Serenade Chocolate Dream Bicycle Rainbow Dragon Bamboo',76,57.0,5277,'Amelia Paisley','Ezra Violet','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Firefly Adventure','Thinking Castle Whimsical Adventure Jumping Horizon Telescope Carousel Butterfly Mountain Mystery Opulent Singing Velvet Aurora Enchantment Butterfly Castle Radiance Radiance Chocolate Singing Galaxy Galaxy Trampoline Trampoline Whisper Symphony Aurora Dancing Velvet Carousel Treasure Symphony Radiance Whimsical Moonlight Dream Mountain Castle',97,38.800000000000004,6953,'Levi Emilia','Asher Emily','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Galaxy Carousel','Bicycle Dream Dancing Mirage Castle Symphony Mystery Ocean Quicksilver Swimming Radiance Reading Eating Saffron Telescope Mystery Whisper Treasure Potion Telescope Sleeping Rainbow Chocolate Castle Writing Thinking Writing Whimsical Jumping Running Mystery Quicksilver Mystery Serenade Mountain Dream Running Starlight Whisper Mountain',15,12.0,9966,'Charlotte Leilani','Wyatt Julian','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mountain Butterfly Moonlight','Echo Starlight Echo Symphony Telescope Mountain Butterfly Carousel Opulent Secret Saffron Horizon Euphoria Swimming Echo Echo Adventure Tranquility Carnival Carousel Ocean Aurora Galaxy Radiance Velvet Tranquility Thinking Rainbow Mystery Serenade Aurora Euphoria Adventure Bamboo Galaxy Trampoline Ocean Secret Euphoria Bamboo',66,13.199999999999996,1322,'Alexander Scarlett','Ethan Jackson','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Saffron Euphoria','Apple Mystery Eating Galaxy Secret Dragon Quicksilver Dream Bicycle Apple Zephyr Galaxy Serendipity Mountain Radiance Singing Rainbow Moonlight Firefly Carnival Euphoria Symphony Mirage Singing Serenade Zephyr Bamboo Tranquility Velvet Horizon Swimming Telescope Enchantment Eating Jumping Quicksilver Butterfly Telescope Carnival Carousel',3,2.25,8552,'Carter Abigail','Ethan Ezekiel','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Enchantment Serenade','Sleeping Running Apple Mountain Dream Moonlight Carnival Twilight Running Eating Adventure Echo Symphony Radiance Swimming Mirage Running Mystery Elephant Dragon Jumping Horizon Elephant Mirage Singing Quicksilver Eating Echo Potion Whimsical Velvet Serenade Echo Serenade Bamboo Euphoria Mountain Zephyr Velvet Running',69,51.75,4132,'Lily Jackson','Madison Maya','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Cascade Rainbow','Jumping Whimsical Galaxy Telescope Twilight Butterfly Enchantment Singing Velvet Galaxy Trampoline Radiance Sunshine Tranquility Firefly Serenade Firefly Dream Adventure Dragon Dancing Dragon Mirage Jumping Piano Dancing Cascade Carnival Apple Chocolate Piano Chocolate Trampoline Carousel Elephant Mountain Running Zephyr Butterfly Swimming',1,1,5140,'Grayson Michael','Lucas Maverick','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Jumping Castle Treasure','Butterfly Adventure Jumping Elephant Horizon Mountain Potion Adventure Swimming Ocean Dancing Lighthouse Secret Carnival Swimming Velvet Mountain Trampoline Mystery Dream Mystery Bicycle Piano Symphony Cascade Elephant Aurora Symphony Firefly Whisper Radiance Opulent Twilight Potion Echo Piano Echo Dancing Chocolate Bicycle',67,33.5,8698,'Jackson Olivia','Nova Olivia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Lighthouse Dream','Starlight Zephyr Quicksilver Carnival Writing Opulent Reading Trampoline Enchantment Chocolate Radiance Quicksilver Radiance Mirage Horizon Zephyr Harmony Zephyr Twilight Writing Galaxy Serenade Mystery Mystery Potion Starlight Writing Sunshine Zephyr Telescope Zephyr Ocean Lighthouse Dream Secret Piano Euphoria Piano Firefly Cascade',92,46.0,7968,'Emily Benjamin','Gabriel Matthew','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Velvet Potion','Reading Potion Mirage Writing Adventure Sunshine Butterfly Eating Dream Starlight Mystery Adventure Saffron Opulent Velvet Mountain Apple Quicksilver Dancing Swimming Euphoria Treasure Dream Saffron Treasure Whimsical Velvet Serenade Butterfly Harmony Potion Piano Carnival Velvet Cascade Tranquility Eating Opulent Galaxy Echo',86,64.5,2854,'Harper Asher','Aurora Mateo','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Radiance Writing','Quicksilver Carousel Rainbow Enchantment Lighthouse Potion Rainbow Saffron Harmony Twilight Jumping Starlight Mystery Opulent Carnival Bicycle Tranquility Whimsical Telescope Starlight Secret Elephant Mirage Serenade Serenade Dragon Dragon Carnival Elephant Reading Dream Trampoline Galaxy Piano Castle Symphony Saffron Dancing Mirage Zephyr',67,67,4764,'Maverick Emma','Levi Camila','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Writing Carousel','Chocolate Whimsical Euphoria Thinking Singing Twilight Mountain Opulent Treasure Enchantment Chocolate Lighthouse Thinking Mirage Writing Serendipity Horizon Writing Twilight Piano Sleeping Adventure Butterfly Castle Piano Apple Trampoline Bicycle Carousel Mirage Dancing Eating Chocolate Trampoline Apple Castle Dragon Galaxy Ocean Sleeping',64,25.6,5685,'Gianna Eleanor','Mia Ezra','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Radiance Harmony Reading','Velvet Thinking Whisper Saffron Mountain Secret Horizon Quicksilver Treasure Sleeping Zephyr Eating Euphoria Secret Aurora Galaxy Whimsical Mountain Secret Mystery Potion Moonlight Euphoria Adventure Saffron Mirage Harmony Enchantment Running Mirage Rainbow Treasure Cascade Horizon Echo Velvet Symphony Velvet Serendipity Euphoria',30,22.5,3579,'Mia Nova','Josiah Olivia','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Starlight Velvet','Galaxy Running Whisper Whimsical Serendipity Apple Carnival Horizon Chocolate Sunshine Galaxy Opulent Dragon Lighthouse Whisper Rainbow Starlight Swimming Starlight Starlight Radiance Radiance Dancing Harmony Carnival Chocolate Ocean Dancing Mystery Quicksilver Chocolate Euphoria Velvet Enchantment Mountain Carousel Ocean Saffron Cascade Mountain',43,38.7,8772,'Theo Leo','Carter Ella','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Dancing Radiance','Quicksilver Quicksilver Cascade Radiance Adventure Carousel Enchantment Writing Dancing Lighthouse Cascade Bamboo Eating Dancing Telescope Dragon Dream Starlight Cascade Sunshine Sunshine Aurora Reading Euphoria Bicycle Potion Writing Bicycle Whimsical Dream Dream Whimsical Ocean Serenade Moonlight Firefly Apple Horizon Dancing Saffron',94,84.6,5513,'Matthew William','Ezekiel Nora','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Echo Secret','Radiance Galaxy Quicksilver Saffron Quicksilver Moonlight Sleeping Mountain Eating Serenade Moonlight Chocolate Enchantment Eating Ocean Harmony Whisper Enchantment Harmony Serenade Thinking Whisper Velvet Firefly Dream Jumping Secret Carnival Serendipity Opulent Secret Galaxy Bamboo Sleeping Serenade Twilight Carnival Echo Lighthouse Harmony',2,1.0,3187,'Penelope Aiden','Julian Oliver','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Rainbow Dragon','Serenade Carousel Opulent Carousel Sleeping Bamboo Secret Secret Adventure Saffron Galaxy Singing Euphoria Swimming Serendipity Dancing Whisper Running Tranquility Aurora Firefly Swimming Treasure Aurora Carnival Symphony Dragon Butterfly Zephyr Velvet Bamboo Harmony Swimming Galaxy Bamboo Butterfly Apple Dragon Harmony Secret',77,38.5,3415,'Ezekiel Amelia','Elias Elijah','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Echo Horizon','Firefly Trampoline Writing Moonlight Whimsical Carnival Quicksilver Enchantment Aurora Moonlight Writing Bicycle Echo Butterfly Starlight Velvet Sleeping Twilight Quicksilver Trampoline Eating Dragon Firefly Singing Horizon Twilight Saffron Saffron Lighthouse Mountain Elephant Potion Potion Firefly Serenade Eating Mountain Thinking Whimsical Harmony',85,34.0,8265,'Lucas Sophia','Henry Ezra','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Ocean Bamboo','Symphony Dream Mirage Sunshine Lighthouse Opulent Singing Enchantment Potion Quicksilver Serendipity Quicksilver Quicksilver Radiance Opulent Jumping Serendipity Sleeping Carousel Treasure Butterfly Zephyr Serendipity Serendipity Potion Whimsical Euphoria Carousel Radiance Trampoline Eating Radiance Bamboo Symphony Secret Firefly Potion Dragon Sunshine Whisper',10,4.0,8399,'Willow Mila','Muhammad Isaiah','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Opulent Rainbow','Cascade Thinking Symphony Telescope Potion Opulent Adventure Treasure Thinking Tranquility Serenade Dream Castle Treasure Running Writing Sleeping Ocean Bamboo Symphony Piano Harmony Harmony Mystery Echo Cascade Castle Symphony Starlight Potion Rainbow Whisper Sleeping Castle Jumping Dancing Horizon Tranquility Echo Castle',44,35.2,9745,'Leilani Jack','Willow Benjamin','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Echo Carnival','Trampoline Writing Twilight Eating Secret Adventure Galaxy Echo Apple Enchantment Whisper Echo Harmony Twilight Writing Serenade Butterfly Whimsical Sunshine Adventure Dragon Cascade Carnival Enchantment Starlight Singing Galaxy Moonlight Twilight Carousel Radiance Quicksilver Velvet Elephant Ocean Horizon Mirage Echo Horizon Zephyr',15,6.0,1266,'Naomi Willow','Zoey Elias','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Swimming Horizon Saffron','Butterfly Piano Cascade Reading Running Cascade Enchantment Rainbow Serendipity Apple Dream Sleeping Castle Enchantment Swimming Butterfly Dream Butterfly Piano Whisper Carousel Secret Rainbow Whimsical Secret Tranquility Horizon Dragon Velvet Quicksilver Mountain Elephant Saffron Dancing Carnival Carousel Carousel Twilight Secret Carnival',21,4.199999999999999,5561,'Isaiah Muhammad','Grayson Grayson','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Rainbow Potion','Elephant Apple Butterfly Jumping Euphoria Lighthouse Lighthouse Dancing Chocolate Piano Reading Tranquility Harmony Lighthouse Tranquility Thinking Opulent Moonlight Carousel Reading Reading Jumping Writing Echo Tranquility Enchantment Rainbow Adventure Opulent Running Apple Ocean Echo Velvet Moonlight Rainbow Aurora Jumping Bamboo Moonlight',99,49.5,7489,'Olivia Madison','Scarlett Jayden','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Carnival Adventure','Quicksilver Twilight Quicksilver Moonlight Velvet Harmony Writing Chocolate Telescope Moonlight Bicycle Radiance Treasure Serendipity Galaxy Aurora Running Velvet Secret Euphoria Moonlight Running Galaxy Adventure Castle Piano Swimming Mirage Echo Mystery Symphony Rainbow Bamboo Whimsical Butterfly Running Apple Serendipity Trampoline Tranquility',44,22.0,1216,'Mateo Sebastian','Willow Liam','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Dancing Quicksilver','Butterfly Bamboo Carnival Swimming Butterfly Swimming Echo Elephant Rainbow Chocolate Symphony Thinking Bamboo Secret Tranquility Mountain Euphoria Treasure Firefly Ocean Adventure Harmony Eating Carnival Symphony Lighthouse Swimming Chocolate Harmony Rainbow Jumping Echo Radiance Cascade Carnival Velvet Firefly Castle Castle Harmony',28,21.0,6200,'Nora Aiden','Isla Samuel','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Jumping Writing Singing','Carousel Mystery Trampoline Butterfly Piano Radiance Mystery Telescope Lighthouse Jumping Harmony Aurora Mirage Mountain Harmony Swimming Sleeping Butterfly Velvet Galaxy Mystery Adventure Whisper Mirage Running Cascade Harmony Galaxy Velvet Starlight Enchantment Saffron Bamboo Galaxy Twilight Eating Opulent Serendipity Piano Aurora',89,22.25,3304,'Miles Harper','Nora David','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Euphoria Mystery','Quicksilver Castle Thinking Horizon Firefly Bicycle Sunshine Rainbow Singing Firefly Dancing Symphony Zephyr Euphoria Carousel Rainbow Apple Secret Telescope Tranquility Adventure Dragon Tranquility Horizon Mirage Sunshine Carousel Serendipity Firefly Whisper Zephyr Mirage Elephant Treasure Euphoria Velvet Mirage Sleeping Potion Carousel',17,6.800000000000001,1426,'Eleanor Logan','Luna Athena','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Firefly Running','Secret Mystery Dragon Saffron Chocolate Quicksilver Adventure Secret Twilight Carousel Twilight Aurora Velvet Castle Galaxy Quicksilver Adventure Dragon Moonlight Cascade Bamboo Mystery Tranquility Horizon Harmony Chocolate Dream Moonlight Velvet Whisper Tranquility Secret Lighthouse Carousel Chocolate Serendipity Serendipity Dream Enchantment Firefly',35,35,130,'Noah Isabella','Lucas Matthew','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Carnival Whisper','Potion Velvet Rainbow Aurora Treasure Chocolate Mirage Velvet Velvet Running Opulent Serendipity Tranquility Butterfly Reading Elephant Dragon Saffron Moonlight Elephant Rainbow Velvet Starlight Serenade Eating Writing Echo Aurora Lighthouse Saffron Potion Cascade Sleeping Serendipity Lighthouse Carousel Opulent Moonlight Aurora Telescope',59,23.6,5818,'Sebastian Hudson','Emilia Zoe','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Tranquility Telescope','Galaxy Echo Moonlight Firefly Enchantment Chocolate Sleeping Secret Secret Sleeping Thinking Adventure Eating Dream Whisper Tranquility Secret Dream Starlight Mystery Carnival Piano Butterfly Running Singing Quicksilver Serenade Velvet Dream Zephyr Moonlight Dancing Symphony Reading Radiance Sleeping Serenade Elephant Firefly Cascade',86,43.0,7342,'Ellie Emma','Eliana Jack','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Dragon Firefly','Serendipity Lighthouse Ocean Rainbow Sleeping Starlight Reading Carousel Quicksilver Carousel Enchantment Zephyr Sleeping Rainbow Mirage Starlight Tranquility Castle Thinking Moonlight Mirage Symphony Sunshine Firefly Mystery Mountain Potion Enchantment Rainbow Mirage Cascade Castle Trampoline Carousel Moonlight Velvet Eating Potion Lighthouse Elephant',56,14.0,7416,'Waylon Chloe','Abigail Hazel','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Tranquility Carousel','Firefly Telescope Mirage Apple Whimsical Enchantment Echo Secret Zephyr Serendipity Adventure Horizon Thinking Thinking Radiance Cascade Reading Whimsical Elephant Aurora Carnival Harmony Tranquility Bicycle Butterfly Whimsical Euphoria Treasure Opulent Butterfly Euphoria Lighthouse Adventure Echo Piano Mountain Castle Dancing Harmony Velvet',27,6.75,1349,'Ellie Naomi','Maverick Alexander','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Dancing Jumping','Reading Lighthouse Horizon Twilight Mystery Running Telescope Horizon Enchantment Running Saffron Twilight Carousel Writing Mountain Sunshine Euphoria Zephyr Saffron Firefly Treasure Carousel Moonlight Twilight Radiance Moonlight Enchantment Eating Sunshine Singing Cascade Quicksilver Galaxy Swimming Saffron Zephyr Elephant Whimsical Trampoline Sunshine',55,55,3083,'Hudson Charlotte','Penelope Zoe','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Serendipity Dancing','Telescope Aurora Dream Cascade Galaxy Castle Rainbow Mystery Horizon Cascade Elephant Rainbow Bamboo Running Butterfly Euphoria Adventure Starlight Carnival Carousel Carousel Apple Echo Mountain Eating Secret Telescope Cascade Whimsical Enchantment Saffron Serendipity Bicycle Quicksilver Quicksilver Euphoria Singing Piano Tranquility Carousel',61,24.4,8659,'William Eliana','Logan Abigail','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Elephant Potion','Firefly Telescope Chocolate Bamboo Bamboo Thinking Tranquility Opulent Secret Carnival Bamboo Ocean Zephyr Radiance Velvet Enchantment Jumping Eating Symphony Singing Elephant Bamboo Lighthouse Lighthouse Adventure Treasure Running Dream Whimsical Serendipity Whimsical Quicksilver Starlight Adventure Carnival Chocolate Serenade Jumping Chocolate Cascade',58,11.599999999999994,4731,'Jackson Willow','Layla Elias','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Serenade Telescope','Serenade Bicycle Sleeping Dragon Jumping Mystery Quicksilver Bamboo Whisper Dancing Rainbow Dancing Euphoria Carnival Dream Firefly Piano Euphoria Cascade Saffron Bamboo Lighthouse Dragon Adventure Telescope Telescope Bicycle Velvet Opulent Adventure Secret Cascade Whisper Chocolate Butterfly Serenade Velvet Secret Thinking Zephyr',79,15.799999999999997,5885,'Aiden Gabriel','Zoe Ava','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Velvet Moonlight','Whisper Swimming Thinking Swimming Telescope Tranquility Velvet Cascade Starlight Cascade Echo Opulent Zephyr Butterfly Sleeping Enchantment Opulent Treasure Radiance Dream Serendipity Bamboo Enchantment Euphoria Secret Zephyr Saffron Harmony Serendipity Ocean Rainbow Symphony Whisper Whisper Singing Aurora Symphony Bamboo Symphony Castle',3,3,5420,'Gabriel Aiden','Evelyn Kai','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Elephant Ocean','Rainbow Telescope Serendipity Firefly Enchantment Whimsical Serendipity Velvet Sleeping Reading Mountain Writing Velvet Aurora Mountain Twilight Writing Harmony Tranquility Dancing Reading Apple Tranquility Thinking Twilight Treasure Secret Moonlight Trampoline Opulent Serendipity Whisper Castle Whisper Chocolate Serenade Sleeping Carousel Bamboo Butterfly',4,1.6,1604,'Theodore Sofia','Kai Grace','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Carousel Firefly','Jumping Zephyr Mountain Adventure Ocean Dragon Castle Carousel Dream Echo Firefly Ocean Saffron Trampoline Firefly Bicycle Opulent Saffron Bamboo Rainbow Piano Elephant Sunshine Euphoria Running Jumping Mystery Dream Saffron Firefly Galaxy Reading Sleeping Piano Bicycle Castle Firefly Whisper Telescope Rainbow',78,78,7230,'Daniel Jackson','Maverick James','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serendipity Cascade Potion','Dragon Radiance Bicycle Enchantment Enchantment Symphony Aurora Swimming Moonlight Harmony Mystery Carnival Whisper Velvet Velvet Quicksilver Adventure Mountain Harmony Velvet Twilight Moonlight Horizon Starlight Carnival Tranquility Whisper Whimsical Butterfly Bamboo Bicycle Twilight Treasure Castle Ocean Treasure Swimming Rainbow Euphoria Elephant',58,23.200000000000003,1013,'Harper Charlotte','Madison Liam','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Mystery Butterfly','Jumping Secret Quicksilver Mirage Jumping Carnival Zephyr Ocean Opulent Thinking Potion Quicksilver Chocolate Running Twilight Velvet Velvet Quicksilver Firefly Bicycle Dancing Rainbow Apple Adventure Euphoria Bicycle Symphony Enchantment Mystery Velvet Elephant Velvet Carnival Starlight Carousel Rainbow Dancing Eating Chocolate Dream',98,39.2,7815,'Nova Hudson','Mila Isla','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Thinking Sleeping','Treasure Treasure Eating Serendipity Ocean Adventure Lighthouse Aurora Velvet Velvet Whisper Velvet Reading Castle Sleeping Enchantment Velvet Piano Bicycle Rainbow Treasure Adventure Bicycle Bicycle Piano Dream Sleeping Dragon Treasure Telescope Horizon Running Tranquility Dancing Treasure Carnival Carnival Butterfly Lighthouse Serendipity',27,6.75,9193,'Ellie Aria','Luke Isabella','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Singing Piano','Aurora Galaxy Tranquility Symphony Starlight Singing Whisper Serenade Euphoria Secret Bicycle Mountain Secret Adventure Trampoline Dream Ocean Carnival Radiance Velvet Sleeping Enchantment Symphony Harmony Reading Telescope Mystery Ocean Carnival Galaxy Whisper Trampoline Eating Writing Galaxy Mountain Castle Harmony Thinking Saffron',28,11.2,7330,'Ezra Aria','Olivia Aurora','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Treasure Horizon','Elephant Saffron Echo Horizon Mirage Euphoria Adventure Piano Treasure Bicycle Twilight Telescope Potion Bicycle Castle Cascade Sleeping Velvet Carnival Velvet Opulent Singing Castle Echo Velvet Enchantment Dancing Mountain Horizon Velvet Bamboo Dragon Carousel Piano Serenade Treasure Telescope Harmony Opulent Tranquility',80,80,3225,'Noah Theo','Charlotte Riley','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Elephant Dancing','Dragon Swimming Starlight Eating Zephyr Dream Mountain Piano Dream Apple Thinking Twilight Carousel Potion Chocolate Eating Dragon Symphony Bicycle Mystery Cascade Carnival Swimming Elephant Secret Mystery Euphoria Bamboo Firefly Dancing Singing Tranquility Sleeping Eating Trampoline Potion Reading Velvet Opulent Dragon',98,88.2,3182,'Samuel Avery','Mateo Charlotte','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Castle Firefly Apple','Trampoline Singing Twilight Carnival Horizon Symphony Echo Whisper Lighthouse Dragon Moonlight Harmony Saffron Galaxy Serendipity Treasure Eating Elephant Serendipity Treasure Echo Sunshine Piano Piano Harmony Enchantment Piano Treasure Writing Horizon Dream Mountain Singing Galaxy Galaxy Rainbow Treasure Carnival Telescope Aurora',83,16.599999999999994,9624,'Owen Luna','Muhammad Lily','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Carnival Ocean','Quicksilver Bicycle Reading Eating Singing Moonlight Enchantment Cascade Chocolate Trampoline Saffron Piano Dancing Tranquility Reading Jumping Mystery Tranquility Saffron Dream Sleeping Dancing Harmony Harmony Eating Velvet Treasure Velvet Thinking Jumping Galaxy Mystery Symphony Mirage Velvet Potion Running Velvet Eating Velvet',65,26.0,4040,'Oliver Henry','Sophia Lily','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Running Apple','Carousel Trampoline Velvet Bamboo Radiance Ocean Jumping Galaxy Serenade Twilight Thinking Serenade Serendipity Mirage Treasure Sunshine Saffron Symphony Sunshine Rainbow Enchantment Opulent Jumping Horizon Harmony Running Moonlight Harmony Piano Zephyr Chocolate Jumping Galaxy Apple Harmony Zephyr Eating Enchantment Writing Carousel',2,1.6,2281,'Sebastian Maya','Isla Nora','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Jumping Sleeping','Harmony Carousel Carnival Bicycle Whimsical Velvet Castle Opulent Sunshine Horizon Opulent Running Jumping Euphoria Rainbow Butterfly Bamboo Ocean Echo Moonlight Euphoria Cascade Aurora Dancing Moonlight Saffron Telescope Running Aurora Mirage Whisper Whisper Eating Aurora Whisper Reading Writing Butterfly Saffron Eating',71,28.4,4603,'Riley Abigail','Matthew Elena','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Galaxy Enchantment','Adventure Quicksilver Enchantment Mystery Dragon Whisper Treasure Dream Ocean Ocean Chocolate Lighthouse Whimsical Mountain Writing Velvet Eating Reading Trampoline Castle Harmony Moonlight Horizon Starlight Saffron Dream Singing Ocean Carousel Dream Carnival Eating Cascade Horizon Horizon Castle Starlight Lighthouse Zephyr Chocolate',24,9.600000000000001,9427,'Luke Levi','Gianna Gabriel','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Starlight Apple','Twilight Velvet Twilight Dancing Sleeping Symphony Mystery Bicycle Jumping Mirage Quicksilver Lighthouse Carnival Piano Mystery Thinking Cascade Harmony Elephant Ocean Saffron Bicycle Starlight Mountain Adventure Whimsical Chocolate Serenade Swimming Dancing Writing Carnival Dragon Radiance Telescope Rainbow Serenade Carnival Firefly Serendipity',47,47,2289,'Mia Nora','Jacob Ethan','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Chocolate Quicksilver','Thinking Whisper Jumping Moonlight Bamboo Aurora Reading Eating Singing Dragon Tranquility Starlight Tranquility Treasure Eating Serenade Aurora Piano Rainbow Potion Writing Adventure Opulent Firefly Bicycle Lighthouse Mountain Eating Moonlight Reading Swimming Zephyr Chocolate Ocean Sunshine Treasure Quicksilver Twilight Bamboo Velvet',8,2.0,9870,'Camila Emilia','Emma Henry','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Opulent Jumping','Reading Twilight Dancing Galaxy Singing Quicksilver Symphony Chocolate Potion Bamboo Opulent Moonlight Reading Telescope Velvet Galaxy Elephant Aurora Serenade Velvet Mountain Harmony Thinking Horizon Tranquility Butterfly Castle Swimming Carousel Euphoria Zephyr Dancing Thinking Galaxy Tranquility Serendipity Velvet Eating Secret Secret',43,21.5,1634,'Gianna Aiden','Sofia Levi','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Tranquility Treasure','Serendipity Butterfly Carnival Symphony Carousel Apple Ocean Butterfly Piano Treasure Eating Piano Trampoline Echo Carnival Harmony Treasure Lighthouse Castle Velvet Mystery Potion Singing Mystery Adventure Whisper Galaxy Galaxy Writing Echo Carnival Symphony Trampoline Symphony Aurora Aurora Quicksilver Symphony Telescope Running',68,17.0,561,'Ezekiel Emily','Sofia Santiago','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Sunshine Butterfly','Sleeping Lighthouse Bicycle Carnival Sleeping Castle Cascade Potion Trampoline Harmony Serendipity Adventure Telescope Mountain Whisper Cascade Velvet Mirage Serendipity Eating Mountain Adventure Swimming Secret Carnival Velvet Thinking Velvet Serenade Sunshine Symphony Horizon Echo Whimsical Radiance Swimming Bamboo Whisper Writing Bamboo',10,7.5,2239,'Avery Hazel','Benjamin James','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Moonlight Serendipity Telescope','Trampoline Harmony Lighthouse Dream Cascade Reading Carnival Harmony Jumping Potion Reading Telescope Mirage Harmony Reading Dragon Whisper Singing Quicksilver Whimsical Reading Harmony Chocolate Carousel Trampoline Running Bicycle Reading Bicycle Bamboo Cascade Twilight Writing Castle Whimsical Firefly Reading Harmony Carnival Carnival',30,30,582,'Theo Grayson','Levi Jacob','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Horizon Starlight','Serenade Velvet Saffron Quicksilver Sunshine Whisper Serendipity Rainbow Eating Starlight Euphoria Jumping Chocolate Adventure Serenade Zephyr Jumping Enchantment Writing Saffron Euphoria Running Velvet Secret Starlight Running Firefly Ocean Bicycle Eating Thinking Apple Castle Zephyr Harmony Apple Zephyr Singing Thinking Saffron',80,16.0,9081,'Theo Alexander','Charlotte Theo','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Mirage Whimsical','Radiance Writing Galaxy Zephyr Thinking Rainbow Treasure Thinking Swimming Aurora Enchantment Moonlight Twilight Quicksilver Zephyr Carousel Serendipity Eating Starlight Carousel Writing Castle Whisper Radiance Firefly Reading Jumping Bamboo Eating Sleeping Serenade Horizon Treasure Potion Whimsical Mountain Eating Galaxy Velvet Telescope',82,41.0,2052,'Mateo Penelope','Kai Josiah','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Thinking Carnival','Piano Running Chocolate Castle Writing Carousel Writing Whimsical Bicycle Eating Carousel Zephyr Thinking Velvet Butterfly Opulent Enchantment Swimming Saffron Singing Enchantment Reading Adventure Mirage Sleeping Opulent Firefly Lighthouse Horizon Cascade Bicycle Dragon Writing Tranquility Dragon Serendipity Mystery Thinking Tranquility Serendipity',9,3.6000000000000005,1914,'Josiah Ezekiel','Jack Gabriel','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Opulent Writing','Potion Radiance Butterfly Potion Thinking Singing Dream Running Bicycle Swimming Lighthouse Swimming Aurora Rainbow Mirage Carousel Mountain Potion Dancing Dancing Carousel Velvet Firefly Carnival Carnival Carousel Ocean Echo Echo Potion Euphoria Lighthouse Dancing Carousel Quicksilver Castle Lighthouse Mirage Serenade Symphony',46,41.4,613,'Mason Waylon','Aria Elizabeth','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Carnival Swimming','Secret Rainbow Twilight Castle Whisper Mirage Whimsical Running Dream Whimsical Trampoline Sleeping Carousel Ocean Velvet Eating Euphoria Tranquility Bicycle Writing Saffron Harmony Sleeping Moonlight Bicycle Whimsical Tranquility Writing Opulent Whimsical Whisper Trampoline Singing Thinking Bicycle Castle Trampoline Secret Thinking Starlight',100,20.0,1798,'Elena Sebastian','Carter Aurora','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Galaxy Carnival','Secret Serenade Treasure Horizon Zephyr Singing Moonlight Ocean Euphoria Apple Swimming Harmony Trampoline Apple Thinking Echo Sunshine Running Carnival Bicycle Butterfly Moonlight Serendipity Castle Rainbow Dream Whimsical Reading Bamboo Elephant Chocolate Trampoline Opulent Serendipity Mystery Euphoria Carousel Running Reading Jumping',4,3.2,2421,'Leo Maverick','Muhammad Logan','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Potion Saffron','Trampoline Writing Twilight Carousel Ocean Mirage Lighthouse Firefly Whisper Piano Telescope Lighthouse Reading Euphoria Tranquility Horizon Thinking Mystery Writing Trampoline Whimsical Bicycle Piano Harmony Piano Euphoria Horizon Dream Tranquility Eating Euphoria Telescope Starlight Sunshine Bamboo Whisper Starlight Piano Whimsical Secret',99,24.75,772,'Grayson Avery','Abigail Jayden','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Harmony Euphoria','Reading Eating Ocean Galaxy Carnival Velvet Velvet Eating Cascade Mirage Whimsical Carousel Starlight Carnival Mirage Eating Starlight Reading Symphony Bamboo Chocolate Mirage Sunshine Thinking Starlight Writing Whisper Apple Serenade Tranquility Serenade Trampoline Sleeping Ocean Opulent Mirage Ocean Radiance Dancing Tranquility',82,16.39999999999999,297,'Henry Mason','Sebastian Ezra','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Bicycle Serendipity','Jumping Potion Jumping Sleeping Twilight Rainbow Galaxy Mirage Symphony Rainbow Mirage Cascade Aurora Treasure Cascade Whimsical Elephant Bamboo Radiance Twilight Lighthouse Symphony Telescope Serenade Starlight Castle Potion Velvet Velvet Lighthouse Piano Velvet Whimsical Singing Dancing Moonlight Telescope Moonlight Trampoline Mountain',56,56,9547,'Avery Muhammad','Sofia Daniel','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Cascade Sleeping','Writing Radiance Singing Reading Starlight Eating Euphoria Starlight Jumping Trampoline Aurora Mystery Quicksilver Chocolate Enchantment Dragon Quicksilver Lighthouse Aurora Castle Carnival Thinking Mountain Serenade Running Bamboo Treasure Jumping Rainbow Potion Serenade Lighthouse Velvet Thinking Telescope Mystery Galaxy Whisper Twilight Euphoria',22,19.8,3135,'Aurora Kai','Kai Gabriel','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Castle Chocolate Piano','Saffron Singing Quicksilver Twilight Piano Radiance Dancing Firefly Jumping Dancing Twilight Ocean Zephyr Radiance Adventure Telescope Eating Velvet Eating Enchantment Opulent Echo Ocean Saffron Symphony Dream Piano Sunshine Carousel Dancing Rainbow Mountain Sunshine Harmony Dragon Sunshine Carousel Dream Cascade Adventure',26,19.5,5400,'Luke Ezekiel','Santiago Charlotte','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Carnival Dancing','Elephant Adventure Zephyr Velvet Writing Velvet Dancing Horizon Telescope Telescope Serendipity Horizon Whisper Running Swimming Euphoria Chocolate Butterfly Writing Secret Velvet Trampoline Enchantment Radiance Tranquility Secret Horizon Bicycle Aurora Bicycle Jumping Opulent Velvet Velvet Echo Telescope Apple Opulent Bamboo Moonlight',96,72.0,6859,'Nova Theo','Julian Elizabeth','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Enchantment Ocean','Radiance Lighthouse Potion Sunshine Mystery Saffron Harmony Serenade Zephyr Writing Potion Carousel Serenade Eating Singing Opulent Bicycle Mirage Carnival Mirage Treasure Mystery Dancing Sleeping Tranquility Treasure Carnival Zephyr Treasure Radiance Piano Sleeping Bicycle Chocolate Rainbow Enchantment Tranquility Mystery Galaxy Elephant',69,62.1,404,'Ezra Ivy','Jack Carter','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Serendipity Velvet','Mountain Potion Opulent Mystery Serendipity Horizon Starlight Castle Apple Writing Dragon Apple Singing Carousel Dancing Dragon Harmony Chocolate Potion Chocolate Galaxy Castle Radiance Rainbow Sleeping Swimming Twilight Ocean Mystery Castle Elephant Bamboo Jumping Symphony Twilight Dragon Secret Dancing Rainbow Lighthouse',8,1.5999999999999996,7374,'Isabella Noah','Elena Liam','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Euphoria Tranquility','Running Mountain Carnival Piano Sunshine Sleeping Serendipity Running Symphony Singing Symphony Velvet Writing Adventure Velvet Mystery Serenade Singing Adventure Butterfly Ocean Dragon Velvet Serendipity Cascade Mystery Echo Velvet Sleeping Piano Writing Running Velvet Echo Lighthouse Writing Aurora Harmony Bicycle Serenade',90,81.0,8889,'Sebastian Athena','Sophia Mateo','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Mystery Piano','Radiance Piano Lighthouse Mystery Radiance Sunshine Bamboo Harmony Trampoline Butterfly Sleeping Bicycle Bamboo Velvet Serendipity Castle Bamboo Mountain Jumping Mystery Whimsical Starlight Piano Mountain Trampoline Thinking Horizon Sleeping Moonlight Bamboo Chocolate Echo Apple Cascade Mystery Reading Bicycle Starlight Horizon Sunshine',89,22.25,2283,'Emma William','Camila Miles','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Elephant Enchantment','Quicksilver Writing Thinking Twilight Echo Echo Sunshine Castle Velvet Dream Dancing Twilight Reading Adventure Ocean Jumping Cascade Galaxy Sunshine Sunshine Jumping Adventure Bicycle Echo Piano Echo Dancing Chocolate Jumping Elephant Ocean Carousel Starlight Sunshine Castle Firefly Running Moonlight Singing Serenade',85,21.25,8952,'Josiah Wyatt','Lucas Hudson','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Sunshine Whisper','Butterfly Trampoline Saffron Whimsical Rainbow Swimming Dragon Running Harmony Saffron Eating Aurora Reading Singing Horizon Velvet Mirage Euphoria Potion Treasure Galaxy Thinking Moonlight Twilight Symphony Apple Swimming Moonlight Piano Mystery Running Cascade Twilight Whisper Castle Secret Mirage Ocean Secret Reading',42,37.8,8388,'Josiah Michael','Santiago Ivy','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Mystery Cascade','Running Writing Castle Piano Thinking Mystery Starlight Dragon Dream Piano Mountain Telescope Harmony Twilight Reading Starlight Rainbow Apple Rainbow Carousel Quicksilver Twilight Mirage Ocean Lighthouse Trampoline Dream Lighthouse Sunshine Serenade Mystery Writing Sunshine Velvet Reading Zephyr Eating Moonlight Serendipity Whisper',22,16.5,9241,'Violet Grayson','Camila Elijah','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Bamboo Ocean','Firefly Cascade Whisper Bamboo Starlight Dream Velvet Thinking Harmony Serenade Velvet Horizon Apple Saffron Moonlight Saffron Velvet Running Moonlight Starlight Serenade Singing Singing Starlight Serendipity Whisper Mountain Dancing Eating Velvet Carnival Serendipity Bamboo Castle Lighthouse Adventure Aurora Mirage Carousel Bamboo',52,41.6,3237,'Ezekiel Leo','Avery David','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Jumping Lighthouse','Echo Swimming Telescope Starlight Enchantment Jumping Apple Opulent Potion Serenade Jumping Harmony Euphoria Dancing Bamboo Euphoria Writing Mystery Potion Echo Mystery Running Mystery Euphoria Radiance Secret Dream Whisper Dancing Mystery Singing Tranquility Singing Running Starlight Firefly Aurora Telescope Whimsical Whisper',38,7.599999999999998,9715,'Jayden Elias','Julian Josiah','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Sunshine Sunshine','Enchantment Eating Sunshine Radiance Moonlight Velvet Adventure Reading Thinking Writing Carousel Apple Velvet Opulent Serenade Moonlight Cascade Thinking Chocolate Ocean Ocean Adventure Rainbow Thinking Running Opulent Butterfly Echo Singing Treasure Reading Treasure Starlight Whisper Cascade Firefly Cascade Butterfly Writing Ocean',69,34.5,3501,'Mila Penelope','Samuel Nova','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Velvet Eating','Telescope Saffron Galaxy Thinking Dancing Bamboo Elephant Potion Dancing Whisper Zephyr Rainbow Mirage Butterfly Serendipity Ocean Running Dream Chocolate Euphoria Adventure Dancing Piano Potion Adventure Firefly Thinking Potion Elephant Dancing Carousel Velvet Carnival Aurora Saffron Moonlight Potion Firefly Starlight Enchantment',56,22.4,1519,'Violet Harper','Jack Amelia','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Secret Horizon','Serendipity Running Euphoria Bamboo Rainbow Mirage Treasure Twilight Serenade Opulent Eating Saffron Potion Cascade Starlight Euphoria Bicycle Eating Enchantment Zephyr Dragon Moonlight Treasure Velvet Harmony Enchantment Dancing Adventure Aurora Castle Mirage Zephyr Starlight Saffron Singing Dragon Mountain Euphoria Harmony Saffron',93,37.2,232,'Chloe Abigail','Jacob Hudson','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Ocean Whimsical','Potion Potion Enchantment Velvet Velvet Bamboo Carousel Apple Horizon Euphoria Potion Reading Apple Velvet Adventure Symphony Mountain Ocean Ocean Ocean Swimming Twilight Swimming Dragon Eating Opulent Apple Galaxy Carnival Aurora Harmony Lighthouse Velvet Galaxy Galaxy Dancing Velvet Telescope Tranquility Rainbow',99,49.5,184,'Scarlett Gabriel','Matthew Maya','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Radiance Running Saffron','Thinking Singing Dream Symphony Sunshine Telescope Telescope Mirage Zephyr Euphoria Symphony Carousel Carousel Trampoline Running Reading Potion Symphony Secret Singing Moonlight Apple Opulent Radiance Moonlight Rainbow Moonlight Treasure Radiance Bamboo Serenade Dragon Velvet Dream Radiance Sleeping Elephant Trampoline Mystery Lighthouse',94,84.6,9123,'Luke Jacob','Emily Asher','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Trampoline Bicycle','Elephant Zephyr Butterfly Cascade Tranquility Potion Euphoria Tranquility Symphony Galaxy Treasure Whisper Serenade Writing Whimsical Whisper Starlight Serenade Rainbow Cascade Treasure Tranquility Butterfly Opulent Whisper Saffron Thinking Reading Castle Radiance Bamboo Sleeping Galaxy Carnival Swimming Carnival Dream Elephant Mountain Butterfly',34,13.600000000000001,9804,'Theo Asher','Emilia Leo','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Sleeping Secret','Whisper Castle Ocean Running Enchantment Eating Opulent Adventure Potion Moonlight Euphoria Opulent Apple Quicksilver Mountain Apple Serenade Galaxy Moonlight Thinking Velvet Moonlight Starlight Twilight Secret Sunshine Sunshine Serendipity Bamboo Aurora Tranquility Dancing Bamboo Piano Whimsical Jumping Lighthouse Galaxy Enchantment Dancing',95,95,3025,'Sophia Grace','Lucas Mila','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Ocean Ocean Twilight','Symphony Singing Saffron Carousel Chocolate Castle Starlight Jumping Whimsical Euphoria Rainbow Castle Mystery Ocean Writing Thinking Rainbow Sleeping Echo Quicksilver Horizon Euphoria Secret Writing Dancing Trampoline Apple Reading Carnival Rainbow Starlight Jumping Chocolate Aurora Quicksilver Apple Writing Cascade Telescope Potion',55,13.75,7526,'David Grayson','Aurora Amelia','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Harmony Cascade','Carousel Mountain Carnival Dragon Rainbow Thinking Eating Whisper Adventure Singing Carousel Adventure Piano Dancing Jumping Singing Whisper Tranquility Whisper Dragon Writing Mirage Firefly Serendipity Running Butterfly Firefly Moonlight Euphoria Potion Velvet Galaxy Running Zephyr Chocolate Whimsical Dragon Velvet Bicycle Ocean',61,54.9,2613,'Emma Scarlett','Leilani Luna','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Reading Jumping','Serenade Mountain Running Whimsical Apple Rainbow Running Cascade Starlight Butterfly Moonlight Mirage Mystery Firefly Velvet Butterfly Running Sleeping Enchantment Quicksilver Elephant Echo Starlight Bamboo Jumping Radiance Velvet Quicksilver Aurora Sleeping Twilight Telescope Saffron Twilight Moonlight Aurora Adventure Tranquility Treasure Tranquility',53,13.25,3800,'Zoey Mason','Elias Chloe','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Apple Piano Velvet','Twilight Ocean Elephant Jumping Adventure Lighthouse Bamboo Thinking Ocean Potion Velvet Twilight Ocean Reading Elephant Writing Whimsical Telescope Zephyr Singing Adventure Quicksilver Lighthouse Ocean Carnival Carnival Symphony Rainbow Chocolate Mystery Carousel Reading Twilight Trampoline Horizon Potion Dancing Dancing Writing Singing',43,38.7,6531,'Sophia Evelyn','Matthew Violet','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Echo Telescope','Rainbow Jumping Mirage Quicksilver Firefly Butterfly Reading Carnival Rainbow Echo Aurora Eating Singing Butterfly Radiance Castle Whimsical Carousel Bamboo Tranquility Mirage Mountain Apple Aurora Saffron Dragon Enchantment Singing Harmony Reading Opulent Symphony Enchantment Apple Moonlight Tranquility Symphony Horizon Zephyr Carnival',21,21,9128,'Daniel Leilani','Emily Zoe','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Trampoline Carousel','Ocean Apple Telescope Dancing Apple Telescope Firefly Mirage Running Saffron Potion Writing Writing Trampoline Swimming Jumping Whisper Velvet Radiance Rainbow Elephant Twilight Dragon Treasure Serendipity Treasure Bamboo Apple Rainbow Apple Bicycle Serenade Adventure Butterfly Cascade Euphoria Firefly Opulent Rainbow Thinking',40,16.0,5498,'Amelia Mateo','James Emilia','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Telescope Mountain Chocolate','Sleeping Dancing Running Saffron Galaxy Writing Serendipity Lighthouse Enchantment Echo Galaxy Trampoline Zephyr Thinking Castle Symphony Ocean Butterfly Whimsical Starlight Whisper Elephant Serendipity Sleeping Butterfly Velvet Whisper Piano Adventure Butterfly Chocolate Eating Treasure Ocean Mirage Carnival Twilight Sunshine Thinking Adventure',43,21.5,7349,'Eliana Nova','Eleanor Zoey','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Dancing Whimsical','Eating Piano Tranquility Reading Radiance Carnival Secret Castle Carousel Dragon Apple Chocolate Tranquility Galaxy Twilight Symphony Trampoline Adventure Apple Potion Dragon Aurora Castle Carnival Twilight Radiance Ocean Castle Singing Mountain Running Chocolate Singing Harmony Galaxy Quicksilver Sunshine Saffron Velvet Potion',23,23,7477,'Willow Athena','Henry Mila','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Piano Tranquility','Adventure Butterfly Writing Carnival Dream Apple Running Mystery Chocolate Echo Radiance Velvet Carnival Treasure Running Bicycle Mountain Zephyr Writing Telescope Sunshine Saffron Symphony Chocolate Starlight Bamboo Velvet Firefly Horizon Velvet Writing Velvet Sunshine Symphony Piano Whisper Rainbow Treasure Rainbow Moonlight',87,43.5,2414,'Madison Asher','Isabella Hazel','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Firefly Sunshine','Euphoria Chocolate Whisper Writing Mirage Tranquility Euphoria Treasure Dream Echo Potion Rainbow Potion Carousel Reading Serenade Thinking Serenade Bicycle Cascade Writing Treasure Castle Sleeping Trampoline Potion Twilight Mirage Echo Tranquility Lighthouse Harmony Piano Symphony Writing Telescope Serenade Radiance Bamboo Symphony',65,16.25,1448,'Elijah Aria','Emily Delilah','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Whimsical Potion','Serenade Tranquility Harmony Elephant Carnival Carnival Sunshine Tranquility Writing Zephyr Serenade Treasure Velvet Potion Eating Whisper Velvet Serendipity Aurora Running Tranquility Treasure Velvet Reading Treasure Running Whimsical Singing Writing Piano Carousel Trampoline Running Velvet Harmony Butterfly Zephyr Aurora Secret Cascade',21,4.199999999999999,3915,'Leo Sebastian','Chloe Mila','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Mirage Rainbow','Harmony Firefly Twilight Enchantment Singing Opulent Dragon Carousel Opulent Eating Velvet Secret Piano Saffron Serenade Mountain Eating Enchantment Butterfly Chocolate Apple Thinking Carousel Cascade Thinking Mystery Cascade Bicycle Ocean Dancing Mirage Euphoria Jumping Carnival Rainbow Chocolate Rainbow Harmony Horizon Secret',59,53.1,6482,'Penelope Chloe','Owen Naomi','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Firefly Jumping','Sleeping Mirage Potion Radiance Dancing Reading Enchantment Reading Chocolate Horizon Dragon Zephyr Lighthouse Harmony Reading Moonlight Carnival Rainbow Singing Dancing Sunshine Moonlight Lighthouse Apple Serendipity Bicycle Eating Thinking Horizon Reading Thinking Telescope Symphony Lighthouse Velvet Dream Euphoria Ocean Mystery Castle',55,13.75,5141,'Gabriel Emily','Athena Riley','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Starlight Galaxy','Whisper Telescope Zephyr Writing Whisper Echo Trampoline Starlight Symphony Singing Serendipity Eating Serendipity Starlight Adventure Jumping Reading Sleeping Dancing Velvet Velvet Carnival Butterfly Writing Symphony Carousel Radiance Writing Potion Treasure Castle Radiance Velvet Chocolate Horizon Symphony Cascade Singing Trampoline Trampoline',12,12,2673,'Layla Jackson','Sophia Ethan','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Jumping Cascade Quicksilver','Piano Bamboo Swimming Velvet Trampoline Whisper Chocolate Apple Twilight Castle Symphony Echo Castle Bamboo Treasure Opulent Castle Castle Chocolate Velvet Lighthouse Castle Harmony Radiance Mystery Echo Telescope Elephant Firefly Twilight Sunshine Mystery Velvet Bicycle Dragon Butterfly Writing Running Piano Quicksilver',57,14.25,7834,'Charlotte Aurora','Chloe Benjamin','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Serenade Writing','Butterfly Moonlight Writing Secret Singing Opulent Harmony Eating Singing Horizon Horizon Dancing Secret Opulent Dream Dancing Trampoline Secret Mystery Potion Chocolate Opulent Cascade Sunshine Echo Sleeping Rainbow Cascade Whisper Trampoline Jumping Cascade Symphony Harmony Thinking Lighthouse Mountain Harmony Quicksilver Dream',51,45.9,3059,'Zoey Eliana','Sofia Chloe','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Running Reading','Running Trampoline Bicycle Opulent Adventure Adventure Carnival Running Enchantment Radiance Reading Potion Potion Chocolate Enchantment Whisper Ocean Piano Enchantment Sunshine Echo Tranquility Moonlight Chocolate Running Eating Sunshine Euphoria Rainbow Whimsical Firefly Potion Bamboo Zephyr Radiance Quicksilver Quicksilver Telescope Eating Galaxy',58,23.200000000000003,20,'Miles Mila','Theodore Ivy','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Secret Adventure','Ocean Whimsical Adventure Saffron Dragon Serenade Zephyr Piano Zephyr Mirage Saffron Thinking Serendipity Opulent Velvet Tranquility Aurora Jumping Harmony Swimming Galaxy Elephant Treasure Writing Lighthouse Zephyr Dancing Apple Galaxy Singing Serendipity Moonlight Bamboo Thinking Serenade Enchantment Ocean Dream Mirage Swimming',87,65.25,8312,'Sophia Eleanor','Mateo Aiden','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Bamboo Quicksilver','Treasure Dancing Reading Quicksilver Swimming Harmony Horizon Harmony Starlight Butterfly Harmony Harmony Serendipity Symphony Harmony Rainbow Euphoria Dream Sleeping Swimming Dragon Harmony Serendipity Zephyr Rainbow Dream Trampoline Starlight Running Secret Bicycle Mountain Chocolate Tranquility Dream Mystery Tranquility Thinking Apple Cascade',96,19.19999999999999,2855,'Santiago Athena','Jayden Ellie','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Horizon Potion','Running Chocolate Opulent Carousel Thinking Running Velvet Treasure Tranquility Thinking Sleeping Elephant Symphony Reading Rainbow Treasure Rainbow Writing Dancing Saffron Running Lighthouse Starlight Whisper Cascade Treasure Harmony Harmony Elephant Aurora Reading Dancing Mystery Whimsical Galaxy Dancing Aurora Galaxy Piano Carnival',48,24.0,792,'Violet Ethan','Carter Ava','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Mystery Serendipity','Whimsical Castle Twilight Adventure Opulent Carousel Potion Mountain Telescope Bicycle Dragon Dragon Radiance Butterfly Lighthouse Whisper Moonlight Piano Ocean Tranquility Sleeping Bamboo Bicycle Treasure Writing Reading Saffron Velvet Firefly Horizon Serendipity Singing Starlight Dream Mountain Chocolate Horizon Secret Dream Symphony',42,33.6,7014,'Luna Elena','Gabriel Liam','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mountain Piano Potion','Serendipity Running Saffron Mystery Whisper Thinking Serendipity Secret Piano Bicycle Castle Castle Piano Mystery Swimming Echo Echo Echo Dragon Opulent Echo Whisper Saffron Dragon Velvet Echo Bamboo Tranquility Carousel Lighthouse Whimsical Running Zephyr Thinking Bicycle Treasure Whisper Mirage Chocolate Rainbow',24,18.0,3413,'Alexander Eliana','Zoey Ella','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Radiance Eating','Dancing Castle Euphoria Telescope Bamboo Whimsical Elephant Jumping Dancing Saffron Castle Thinking Carnival Velvet Sunshine Trampoline Twilight Galaxy Velvet Secret Chocolate Twilight Castle Lighthouse Piano Elephant Serenade Velvet Trampoline Opulent Radiance Sunshine Treasure Mountain Mountain Galaxy Chocolate Whimsical Aurora Jumping',33,13.2,2313,'Charlotte Alexander','Ivy Kai','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Starlight Castle Swimming','Whimsical Firefly Eating Dragon Velvet Velvet Moonlight Chocolate Whisper Sleeping Harmony Whimsical Adventure Adventure Bicycle Trampoline Trampoline Trampoline Carnival Horizon Elephant Bamboo Secret Starlight Bamboo Telescope Twilight Sleeping Moonlight Rainbow Mirage Radiance Swimming Aurora Tranquility Elephant Treasure Enchantment Running Whimsical',6,4.5,9719,'Hudson Logan','Ezra Mila','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Tranquility Serenade','Piano Dragon Jumping Quicksilver Sunshine Rainbow Dancing Treasure Velvet Potion Bicycle Mirage Radiance Velvet Butterfly Telescope Cascade Mountain Sunshine Swimming Secret Adventure Running Aurora Rainbow Carnival Telescope Telescope Whisper Bamboo Bicycle Ocean Piano Twilight Running Carnival Ocean Treasure Firefly Writing',96,76.8,244,'Maverick Michael','Nova Theodore','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Running Starlight','Reading Carousel Serendipity Carousel Velvet Velvet Chocolate Writing Dancing Ocean Euphoria Dragon Telescope Zephyr Adventure Whisper Carnival Cascade Treasure Whisper Running Galaxy Symphony Velvet Running Saffron Running Trampoline Aurora Opulent Lighthouse Telescope Carousel Horizon Firefly Carousel Sunshine Velvet Horizon Treasure',10,2.5,9525,'Mason Isabella','Camila Kai','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Jumping Radiance','Whisper Velvet Rainbow Swimming Mirage Zephyr Whimsical Bicycle Firefly Starlight Mirage Treasure Thinking Mystery Zephyr Singing Sunshine Harmony Bicycle Harmony Lighthouse Chocolate Harmony Whimsical Carousel Whisper Harmony Adventure Sleeping Adventure Treasure Sunshine Treasure Mountain Opulent Apple Dragon Horizon Running Secret',60,60,8739,'Evelyn Isabella','Theodore Theodore','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Twilight Moonlight','Bamboo Jumping Symphony Jumping Serenade Zephyr Sleeping Running Harmony Moonlight Sunshine Serendipity Eating Dream Telescope Galaxy Treasure Galaxy Aurora Dream Butterfly Whimsical Ocean Swimming Horizon Dancing Velvet Echo Moonlight Enchantment Writing Thinking Chocolate Whisper Trampoline Serenade Singing Adventure Piano Apple',82,16.39999999999999,8120,'Luca Nora','Elena Carter','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Starlight Elephant','Bicycle Mirage Euphoria Bamboo Trampoline Galaxy Castle Dancing Ocean Euphoria Quicksilver Galaxy Echo Whisper Treasure Potion Dancing Sleeping Butterfly Radiance Opulent Harmony Mountain Twilight Mountain Echo Dragon Treasure Bicycle Carousel Castle Castle Reading Dragon Butterfly Quicksilver Chocolate Adventure Piano Rainbow',25,10.0,8865,'Michael Zoe','Willow Leo','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Castle Radiance','Running Chocolate Starlight Butterfly Potion Swimming Whimsical Ocean Lighthouse Bamboo Echo Sleeping Saffron Zephyr Secret Jumping Jumping Thinking Running Singing Thinking Saffron Jumping Whimsical Enchantment Potion Cascade Telescope Telescope Galaxy Tranquility Cascade Firefly Radiance Serenade Mirage Elephant Mountain Trampoline Trampoline',70,56.0,998,'Isla Lucas','Ezekiel Leilani','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Radiance Sunshine','Rainbow Swimming Elephant Quicksilver Swimming Running Sleeping Swimming Eating Thinking Radiance Elephant Velvet Bamboo Running Treasure Moonlight Quicksilver Potion Whisper Sleeping Carnival Whisper Saffron Tranquility Opulent Carnival Telescope Opulent Harmony Symphony Serendipity Dragon Harmony Echo Galaxy Elephant Velvet Galaxy Treasure',57,14.25,2618,'Elijah Nora','Jack Amelia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Castle Mirage','Sunshine Starlight Radiance Horizon Saffron Piano Castle Whisper Horizon Thinking Quicksilver Starlight Sleeping Mystery Velvet Aurora Reading Zephyr Dragon Tranquility Telescope Lighthouse Writing Serenade Velvet Tranquility Mountain Symphony Enchantment Carnival Moonlight Butterfly Twilight Carnival Writing Bamboo Firefly Singing Running Ocean',61,30.5,4130,'Ella Logan','Camila Waylon','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Telescope Carousel Horizon','Adventure Whimsical Apple Mystery Mystery Bamboo Treasure Serendipity Opulent Moonlight Ocean Singing Trampoline Cascade Dragon Horizon Piano Trampoline Treasure Bamboo Thinking Castle Moonlight Writing Horizon Galaxy Potion Zephyr Writing Radiance Enchantment Carousel Writing Twilight Galaxy Piano Quicksilver Sunshine Secret Elephant',68,68,4087,'Jacob Elena','Leo Charlotte','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Dream Apple','Harmony Sunshine Eating Carnival Swimming Starlight Mirage Butterfly Zephyr Treasure Singing Twilight Aurora Dream Mystery Trampoline Tranquility Serendipity Mirage Starlight Echo Velvet Bicycle Sleeping Quicksilver Potion Writing Aurora Horizon Mountain Cascade Dream Opulent Radiance Treasure Dancing Firefly Starlight Piano Starlight',58,23.200000000000003,4315,'Penelope Kai','Harper Elijah','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Telescope Harmony','Swimming Castle Jumping Saffron Secret Apple Harmony Tranquility Euphoria Telescope Dancing Horizon Dragon Moonlight Potion Chocolate Moonlight Starlight Singing Castle Rainbow Enchantment Velvet Apple Saffron Tranquility Thinking Running Dragon Mirage Writing Bicycle Mountain Carousel Echo Swimming Butterfly Secret Singing Twilight',99,19.799999999999997,5258,'Penelope Logan','Levi Kai','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serenade Swimming Moonlight','Eating Butterfly Opulent Writing Velvet Potion Harmony Symphony Whimsical Mountain Secret Saffron Symphony Rainbow Firefly Saffron Cascade Mystery Dream Velvet Jumping Serenade Carnival Ocean Carousel Bicycle Bicycle Rainbow Jumping Echo Eating Mountain Moonlight Serendipity Whisper Dancing Starlight Thinking Mountain Quicksilver',66,26.4,9527,'Sofia Camila','Gabriel Delilah','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Carnival Whimsical','Apple Piano Horizon Chocolate Galaxy Dragon Singing Sunshine Writing Trampoline Dream Bicycle Firefly Potion Carnival Harmony Swimming Aurora Aurora Echo Mirage Telescope Singing Saffron Secret Potion Opulent Dream Galaxy Mystery Running Carousel Eating Radiance Mystery Mirage Treasure Serenade Elephant Whimsical',76,76,3748,'Gabriel Ava','Levi Mia','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Mirage Jumping','Bicycle Horizon Galaxy Sunshine Rainbow Adventure Saffron Carousel Swimming Firefly Telescope Butterfly Harmony Twilight Opulent Mirage Harmony Horizon Swimming Enchantment Sleeping Elephant Elephant Bamboo Apple Saffron Galaxy Starlight Sunshine Moonlight Apple Carnival Horizon Sleeping Secret Dancing Tranquility Piano Swimming Quicksilver',99,19.799999999999997,3443,'Isaiah Aurora','Alexander Zoey','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Mountain Lighthouse','Piano Dream Reading Starlight Dream Velvet Symphony Dragon Singing Writing Whisper Starlight Eating Eating Running Singing Eating Horizon Quicksilver Saffron Secret Trampoline Apple Horizon Whimsical Aurora Zephyr Dream Potion Horizon Eating Ocean Zephyr Twilight Secret Swimming Treasure Whimsical Eating Apple',84,21.0,3438,'Charlotte Jayden','Henry Isla','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Elephant Reading','Serendipity Mystery Reading Reading Jumping Carousel Symphony Ocean Chocolate Whisper Horizon Starlight Rainbow Opulent Bamboo Echo Thinking Starlight Saffron Horizon Dream Sunshine Opulent Firefly Euphoria Aurora Potion Galaxy Swimming Serendipity Chocolate Sunshine Starlight Carnival Enchantment Carnival Telescope Rainbow Euphoria Dancing',68,54.4,8629,'William Elias','Ava Amelia','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Whisper Carousel','Swimming Opulent Dragon Velvet Aurora Cascade Thinking Serenade Symphony Trampoline Velvet Swimming Mystery Telescope Running Symphony Symphony Twilight Tranquility Lighthouse Velvet Running Radiance Bicycle Symphony Euphoria Cascade Thinking Singing Telescope Potion Eating Starlight Trampoline Enchantment Radiance Dream Sleeping Enchantment Dragon',44,33.0,6603,'Sophia Leilani','Nova Isaiah','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Moonlight Echo','Carousel Galaxy Chocolate Tranquility Dancing Dancing Treasure Sunshine Sleeping Secret Aurora Cascade Elephant Symphony Whisper Running Euphoria Tranquility Lighthouse Reading Secret Serenade Symphony Dancing Aurora Mountain Bamboo Potion Velvet Trampoline Ocean Quicksilver Ocean Apple Bamboo Butterfly Thinking Telescope Bamboo Galaxy',55,55,1326,'Isla Jacob','Jayden Ethan','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Ocean Adventure','Velvet Serenade Ocean Dream Serenade Lighthouse Singing Quicksilver Jumping Singing Thinking Sleeping Velvet Carousel Piano Horizon Dancing Potion Galaxy Carousel Secret Eating Euphoria Enchantment Carousel Dream Elephant Ocean Ocean Whisper Reading Adventure Jumping Butterfly Thinking Horizon Enchantment Whisper Sleeping Serenade',13,3.25,5147,'Asher David','Violet Josiah','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Butterfly Jumping','Cascade Jumping Castle Bamboo Opulent Eating Castle Horizon Saffron Echo Lighthouse Castle Trampoline Mountain Tranquility Trampoline Euphoria Opulent Bicycle Firefly Tranquility Treasure Whisper Butterfly Butterfly Dragon Galaxy Eating Firefly Radiance Firefly Sunshine Bicycle Dancing Aurora Adventure Aurora Dream Castle Chocolate',53,21.200000000000003,4996,'Leilani Eliana','Evelyn Mila','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Firefly Mountain Butterfly','Radiance Saffron Euphoria Quicksilver Starlight Trampoline Cascade Symphony Quicksilver Lighthouse Dancing Chocolate Starlight Piano Bicycle Ocean Dragon Adventure Euphoria Thinking Apple Radiance Zephyr Serendipity Mountain Eating Whimsical Mountain Elephant Dragon Mirage Echo Starlight Treasure Sunshine Velvet Piano Symphony Writing Saffron',16,6.4,6560,'Luke Henry','Zoey Elizabeth','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Butterfly Cascade','Moonlight Thinking Enchantment Elephant Firefly Ocean Castle Serenade Rainbow Whisper Ocean Opulent Apple Mystery Adventure Mystery Saffron Thinking Lighthouse Carnival Singing Velvet Treasure Treasure Secret Serendipity Dancing Ocean Chocolate Harmony Quicksilver Velvet Saffron Velvet Galaxy Harmony Writing Swimming Euphoria Dragon',25,10.0,3552,'Oliver Elizabeth','Gianna Lucas','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Whisper Zephyr','Elephant Horizon Running Galaxy Sleeping Treasure Dream Opulent Euphoria Serendipity Mirage Galaxy Twilight Elephant Serendipity Serenade Telescope Tranquility Sleeping Sunshine Bamboo Serenade Carousel Cascade Tranquility Zephyr Rainbow Dragon Trampoline Starlight Potion Trampoline Apple Dancing Apple Carousel Jumping Opulent Swimming Enchantment',36,28.8,8661,'Elijah Scarlett','Daniel Nova','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Radiance Chocolate Zephyr','Mystery Singing Galaxy Running Secret Serenade Bamboo Ocean Carnival Tranquility Galaxy Tranquility Castle Whisper Lighthouse Whisper Adventure Eating Velvet Euphoria Swimming Ocean Radiance Bamboo Telescope Echo Running Chocolate Mirage Swimming Radiance Bamboo Aurora Sunshine Moonlight Mountain Velvet Mirage Sunshine Echo',85,63.75,5471,'Zoe Nora','Elijah Naomi','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serendipity Aurora Piano','Cascade Radiance Whimsical Zephyr Rainbow Elephant Piano Whisper Treasure Enchantment Running Sleeping Mountain Elephant Aurora Moonlight Dancing Harmony Carnival Rainbow Sleeping Carnival Secret Aurora Mountain Mirage Harmony Rainbow Whisper Horizon Chocolate Dream Echo Trampoline Radiance Sleeping Sleeping Running Singing Bicycle',74,74,5241,'Samuel Zoey','Charlotte Avery','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Cascade Velvet Mountain','Saffron Velvet Whimsical Sleeping Zephyr Elephant Serenade Velvet Dragon Mirage Secret Treasure Galaxy Adventure Writing Reading Telescope Sleeping Moonlight Carnival Bicycle Castle Dragon Mountain Serendipity Elephant Treasure Rainbow Eating Treasure Velvet Elephant Mountain Whimsical Dancing Lighthouse Galaxy Sleeping Whisper Reading',7,5.25,3148,'Noah Ethan','Nora William','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Whisper Trampoline','Horizon Ocean Zephyr Dragon Rainbow Bamboo Euphoria Carnival Writing Bamboo Swimming Euphoria Jumping Sunshine Bamboo Horizon Enchantment Piano Aurora Bicycle Velvet Tranquility Whisper Running Sleeping Singing Elephant Rainbow Dream Whimsical Galaxy Galaxy Twilight Rainbow Galaxy Secret Sunshine Starlight Jumping Aurora',16,4.0,9086,'Leilani Lucas','Delilah Josiah','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Cascade Castle','Cascade Piano Horizon Mountain Chocolate Potion Twilight Saffron Mirage Eating Moonlight Potion Enchantment Radiance Starlight Velvet Writing Twilight Mirage Potion Tranquility Zephyr Singing Galaxy Carousel Horizon Radiance Velvet Aurora Bamboo Bicycle Eating Moonlight Symphony Sleeping Horizon Moonlight Thinking Swimming Quicksilver',67,33.5,5338,'Zoey Isaiah','Riley Avery','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Swimming Mountain','Enchantment Serendipity Moonlight Running Whimsical Potion Tranquility Velvet Mountain Butterfly Eating Velvet Quicksilver Dragon Bicycle Opulent Saffron Swimming Velvet Apple Whisper Carousel Ocean Echo Bamboo Zephyr Swimming Ocean Eating Apple Opulent Apple Sunshine Writing Carousel Symphony Jumping Velvet Treasure Dancing',87,17.39999999999999,2441,'Leilani Mia','Elena Mateo','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Piano Castle Horizon','Castle Telescope Tranquility Moonlight Butterfly Serendipity Symphony Cascade Galaxy Starlight Treasure Bamboo Firefly Symphony Cascade Enchantment Thinking Elephant Castle Butterfly Sleeping Zephyr Writing Dragon Secret Dragon Apple Velvet Opulent Lighthouse Enchantment Dream Starlight Piano Sleeping Enchantment Harmony Mystery Galaxy Secret',1,0.5,861,'Ezekiel Jackson','Naomi Eliana','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Galaxy Piano','Jumping Radiance Apple Saffron Trampoline Serendipity Symphony Radiance Velvet Carnival Chocolate Bicycle Singing Bamboo Eating Writing Cascade Velvet Radiance Sunshine Velvet Bicycle Harmony Dream Aurora Eating Mountain Bicycle Trampoline Mountain Dream Serendipity Serendipity Velvet Cascade Aurora Butterfly Carousel Velvet Moonlight',73,65.7,3537,'Miles Sofia','Aria Wyatt','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Starlight Opulent Eating','Symphony Piano Mystery Serenade Carnival Cascade Serendipity Dream Thinking Harmony Mirage Telescope Horizon Horizon Echo Dragon Bamboo Eating Twilight Aurora Saffron Potion Echo Ocean Dream Twilight Potion Carnival Symphony Velvet Mirage Radiance Chocolate Sunshine Whimsical Dream Treasure Running Chocolate Adventure',41,16.400000000000002,5647,'Ezekiel Willow','Zoe Naomi','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Adventure Sleeping','Writing Enchantment Butterfly Zephyr Butterfly Singing Adventure Harmony Mystery Apple Tranquility Swimming Aurora Symphony Apple Piano Singing Tranquility Butterfly Quicksilver Twilight Tranquility Singing Telescope Swimming Bicycle Carnival Velvet Serenade Bamboo Sleeping Mirage Mystery Mystery Velvet Jumping Dream Mirage Dream Serendipity',67,50.25,8655,'William Penelope','Jayden Miles','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Writing Velvet','Apple Firefly Firefly Cascade Enchantment Treasure Piano Carousel Elephant Cascade Bamboo Lighthouse Trampoline Adventure Lighthouse Apple Echo Running Velvet Secret Chocolate Carnival Elephant Writing Euphoria Euphoria Galaxy Chocolate Saffron Euphoria Serendipity Tranquility Symphony Treasure Piano Euphoria Dragon Swimming Sleeping Sunshine',58,52.2,4867,'Gianna Madison','Jacob Nova','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Aurora Cascade','Radiance Trampoline Lighthouse Radiance Echo Sunshine Thinking Butterfly Telescope Moonlight Dragon Ocean Tranquility Tranquility Sunshine Serendipity Whisper Cascade Tranquility Mystery Velvet Euphoria Dream Ocean Elephant Opulent Aurora Potion Potion Ocean Harmony Piano Sunshine Saffron Apple Rainbow Bamboo Whisper Dream Telescope',37,14.8,2156,'Ezekiel Olivia','Oliver Luke','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mountain Mountain Sunshine','Chocolate Velvet Writing Tranquility Running Echo Galaxy Tranquility Sunshine Piano Potion Galaxy Rainbow Castle Elephant Singing Velvet Enchantment Piano Euphoria Sleeping Chocolate Bicycle Opulent Dream Eating Tranquility Chocolate Echo Apple Butterfly Mountain Harmony Bamboo Carnival Mirage Swimming Velvet Enchantment Horizon',58,29.0,3153,'Elias Avery','Nora Jack','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Starlight Starlight','Reading Dream Singing Carnival Apple Dragon Serendipity Symphony Thinking Running Lighthouse Telescope Serenade Reading Saffron Apple Chocolate Whisper Apple Quicksilver Castle Mountain Piano Telescope Singing Zephyr Horizon Firefly Swimming Singing Symphony Velvet Echo Sunshine Thinking Ocean Firefly Firefly Velvet Eating',64,16.0,985,'Willow Matthew','Naomi Harper','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Tranquility Harmony Tranquility','Trampoline Elephant Whisper Butterfly Eating Zephyr Serenade Treasure Telescope Zephyr Jumping Velvet Harmony Echo Quicksilver Secret Symphony Euphoria Running Cascade Mountain Thinking Sunshine Cascade Reading Castle Symphony Mystery Ocean Treasure Galaxy Aurora Radiance Whisper Sleeping Dragon Bamboo Firefly Sleeping Secret',19,4.75,6193,'Oliver Santiago','Elias Zoe','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Adventure Trampoline','Apple Velvet Swimming Mountain Dragon Opulent Thinking Bamboo Dream Eating Ocean Galaxy Radiance Telescope Whisper Butterfly Enchantment Eating Sleeping Butterfly Jumping Thinking Serendipity Euphoria Mystery Chocolate Mountain Jumping Serenade Lighthouse Ocean Firefly Starlight Cascade Running Potion Tranquility Velvet Tranquility Thinking',79,31.6,2697,'Naomi Ezekiel','Kai Aurora','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carousel Carousel Quicksilver','Sleeping Mystery Mountain Elephant Velvet Chocolate Carousel Cascade Ocean Sleeping Dancing Aurora Zephyr Velvet Sleeping Zephyr Lighthouse Euphoria Butterfly Telescope Adventure Quicksilver Apple Whisper Dragon Adventure Jumping Enchantment Euphoria Eating Whimsical Mirage Elephant Dragon Trampoline Starlight Whimsical Firefly Carousel Telescope',16,3.1999999999999993,1125,'David Elijah','Josiah Matthew','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Starlight Writing Secret','Horizon Whisper Elephant Reading Aurora Aurora Harmony Singing Chocolate Dream Potion Potion Symphony Elephant Trampoline Elephant Elephant Whisper Chocolate Butterfly Velvet Lighthouse Quicksilver Writing Dancing Thinking Butterfly Apple Echo Mystery Opulent Swimming Radiance Mystery Euphoria Cascade Cascade Sleeping Eating Writing',30,7.5,6105,'Isabella Maya','Abigail Miles','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Telescope Running','Twilight Radiance Moonlight Zephyr Chocolate Jumping Radiance Eating Mountain Reading Enchantment Twilight Bicycle Reading Zephyr Telescope Firefly Sleeping Dancing Elephant Castle Thinking Harmony Dream Mountain Elephant Echo Dream Cascade Horizon Thinking Castle Serenade Lighthouse Twilight Secret Starlight Dancing Telescope Enchantment',58,58,3914,'Olivia Elias','Sebastian Elizabeth','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Whimsical Quicksilver','Dragon Eating Saffron Ocean Velvet Tranquility Potion Radiance Butterfly Opulent Tranquility Treasure Twilight Castle Horizon Sleeping Mountain Telescope Piano Dragon Sunshine Trampoline Harmony Twilight Aurora Sleeping Saffron Dream Horizon Castle Euphoria Echo Whimsical Sunshine Carnival Dream Mountain Jumping Dragon Swimming',39,35.1,93,'Wyatt Mila','Eleanor Elijah','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Eating Quicksilver','Cascade Apple Jumping Jumping Quicksilver Moonlight Treasure Butterfly Mountain Writing Quicksilver Swimming Horizon Symphony Serenade Bamboo Trampoline Galaxy Serendipity Echo Aurora Euphoria Apple Aurora Lighthouse Trampoline Bamboo Jumping Tranquility Carousel Saffron Twilight Harmony Treasure Euphoria Swimming Dream Galaxy Elephant Twilight',41,16.400000000000002,8532,'Luke Emily','Ezra Santiago','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Apple Mountain','Thinking Mystery Mirage Bamboo Sleeping Cascade Harmony Symphony Whisper Quicksilver Starlight Thinking Rainbow Whisper Zephyr Swimming Starlight Harmony Starlight Echo Echo Adventure Aurora Radiance Euphoria Whimsical Serendipity Chocolate Euphoria Potion Symphony Tranquility Firefly Adventure Treasure Whimsical Trampoline Aurora Telescope Jumping',81,32.4,6317,'Leilani Samuel','Ethan Ellie','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Echo Butterfly','Ocean Singing Sunshine Thinking Ocean Ocean Thinking Sleeping Secret Carnival Apple Swimming Dream Radiance Rainbow Dream Whimsical Dancing Telescope Sunshine Telescope Adventure Velvet Treasure Ocean Running Jumping Secret Carousel Firefly Enchantment Dragon Bamboo Elephant Serenade Rainbow Serendipity Twilight Firefly Serendipity',19,3.799999999999999,5580,'Jackson Noah','Ava Jacob','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Dream Telescope','Velvet Lighthouse Euphoria Horizon Opulent Carnival Jumping Horizon Swimming Ocean Cascade Zephyr Dancing Dragon Lighthouse Sunshine Thinking Ocean Eating Symphony Aurora Carnival Quicksilver Running Firefly Echo Butterfly Reading Echo Whimsical Aurora Telescope Firefly Velvet Dragon Swimming Carnival Apple Secret Harmony',6,4.5,3183,'Ella Nova','Olivia Matthew','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Thinking Carousel','Twilight Writing Serenade Apple Ocean Mystery Harmony Whisper Dragon Dragon Dream Piano Carousel Reading Mystery Moonlight Velvet Apple Carnival Adventure Dragon Serendipity Velvet Castle Carousel Aurora Rainbow Singing Dragon Butterfly Moonlight Firefly Mountain Horizon Symphony Mirage Velvet Swimming Eating Harmony',59,14.75,7151,'Eleanor Gianna','Hudson Kai','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Secret Mountain','Secret Dream Eating Dream Moonlight Piano Symphony Horizon Reading Sunshine Chocolate Cascade Mirage Running Radiance Thinking Aurora Running Piano Mirage Radiance Trampoline Zephyr Treasure Jumping Sunshine Zephyr Moonlight Apple Serenade Aurora Euphoria Telescope Mystery Twilight Twilight Carousel Aurora Opulent Trampoline',27,21.6,3220,'Ivy Harper','Amelia Mateo','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Ocean Piano','Starlight Zephyr Reading Horizon Enchantment Butterfly Twilight Aurora Eating Whisper Apple Tranquility Running Adventure Castle Bicycle Carnival Sleeping Carousel Enchantment Writing Mirage Reading Castle Running Writing Enchantment Apple Ocean Rainbow Horizon Echo Thinking Telescope Potion Running Carousel Firefly Rainbow Zephyr',77,19.25,2402,'Luca Gianna','Avery Santiago','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Mystery Treasure','Castle Harmony Eating Harmony Dragon Potion Jumping Elephant Jumping Whisper Whimsical Radiance Running Bamboo Galaxy Firefly Tranquility Zephyr Tranquility Saffron Swimming Symphony Castle Chocolate Whimsical Galaxy Chocolate Moonlight Aurora Twilight Castle Elephant Secret Twilight Mirage Secret Reading Horizon Mystery Whisper',50,25.0,4703,'Athena Matthew','Athena Scarlett','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Enchantment Swimming','Euphoria Bamboo Zephyr Velvet Mirage Saffron Dream Telescope Rainbow Trampoline Dancing Trampoline Thinking Eating Bicycle Opulent Echo Eating Trampoline Opulent Galaxy Horizon Starlight Carousel Serendipity Running Adventure Carnival Elephant Cascade Harmony Saffron Thinking Telescope Velvet Carnival Treasure Piano Jumping Aurora',88,44.0,8559,'Julian Kai','Grayson Gianna','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Enchantment Serendipity','Velvet Adventure Sunshine Apple Whisper Swimming Tranquility Firefly Butterfly Carousel Dragon Rainbow Radiance Adventure Cascade Chocolate Eating Galaxy Velvet Bamboo Treasure Whisper Butterfly Firefly Dream Singing Cascade Starlight Singing Singing Bicycle Dragon Piano Harmony Ocean Telescope Sleeping Horizon Mountain Chocolate',68,27.200000000000003,1507,'Leilani Luke','Evelyn Gianna','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Mirage Dancing','Symphony Aurora Thinking Cascade Bamboo Mirage Twilight Zephyr Firefly Symphony Chocolate Eating Butterfly Twilight Telescope Carousel Eating Thinking Carousel Saffron Treasure Apple Radiance Serenade Starlight Starlight Velvet Bicycle Lighthouse Bamboo Mountain Quicksilver Sunshine Mirage Castle Twilight Mountain Dream Carousel Sleeping',20,4.0,8873,'Mia Santiago','Paisley Leilani','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Serenade Eating','Whisper Sleeping Potion Saffron Velvet Mirage Reading Dragon Tranquility Carousel Serenade Dream Swimming Piano Chocolate Trampoline Elephant Jumping Saffron Radiance Jumping Carousel Dancing Trampoline Aurora Zephyr Firefly Dragon Velvet Carousel Bamboo Treasure Lighthouse Dancing Zephyr Thinking Tranquility Whimsical Trampoline Whisper',50,50,3413,'Maverick Athena','Isaiah Waylon','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Aurora Velvet','Trampoline Treasure Trampoline Moonlight Whisper Chocolate Mirage Radiance Swimming Telescope Eating Potion Galaxy Serendipity Dream Serendipity Secret Reading Secret Zephyr Echo Adventure Quicksilver Potion Firefly Twilight Piano Rainbow Sleeping Radiance Velvet Velvet Firefly Velvet Adventure Quicksilver Galaxy Harmony Potion Treasure',24,6.0,4148,'Madison Theo','Wyatt Ezra','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serendipity Apple Jumping','Radiance Opulent Elephant Zephyr Saffron Treasure Carnival Serendipity Swimming Swimming Velvet Treasure Whisper Enchantment Potion Potion Quicksilver Euphoria Sunshine Mirage Reading Trampoline Carousel Moonlight Galaxy Rainbow Serendipity Bamboo Euphoria Adventure Radiance Quicksilver Horizon Carousel Moonlight Butterfly Potion Starlight Starlight Tranquility',1,0.9,3809,'Violet Charlotte','Elena Jack','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Saffron Symphony','Starlight Ocean Dream Bicycle Singing Adventure Twilight Ocean Trampoline Velvet Horizon Mountain Secret Moonlight Telescope Tranquility Tranquility Thinking Enchantment Enchantment Whisper Elephant Writing Treasure Saffron Treasure Harmony Zephyr Harmony Ocean Potion Reading Serenade Galaxy Jumping Carousel Euphoria Secret Carousel Writing',100,50.0,7956,'William Samuel','Emma Elias','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Galaxy Echo','Mountain Potion Serendipity Moonlight Chocolate Sleeping Dream Singing Whimsical Symphony Zephyr Quicksilver Piano Serenade Moonlight Elephant Moonlight Symphony Telescope Adventure Apple Saffron Zephyr Writing Adventure Bicycle Thinking Euphoria Quicksilver Tranquility Bamboo Bamboo Lighthouse Serendipity Whisper Horizon Adventure Potion Galaxy Dancing',67,60.3,3332,'Hudson Naomi','Asher Madison','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Tranquility Mirage','Symphony Thinking Serenade Quicksilver Bamboo Dragon Ocean Trampoline Eating Potion Trampoline Jumping Quicksilver Rainbow Swimming Whimsical Euphoria Castle Carnival Serendipity Running Eating Aurora Ocean Trampoline Radiance Carnival Bicycle Quicksilver Castle Velvet Euphoria Carousel Dragon Bamboo Castle Saffron Rainbow Echo Opulent',24,9.600000000000001,7906,'Grayson Zoey','Noah Gabriel','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Symphony Starlight','Velvet Thinking Mirage Butterfly Potion Chocolate Singing Sleeping Mirage Serenade Bamboo Mountain Jumping Velvet Chocolate Adventure Potion Carousel Whisper Opulent Whimsical Radiance Carnival Elephant Trampoline Symphony Quicksilver Serenade Writing Swimming Mountain Treasure Chocolate Mystery Treasure Lighthouse Eating Carousel Cascade Swimming',97,97,5101,'Leo Riley','Ivy Mateo','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Writing Sunshine Secret','Tranquility Serenade Reading Piano Whimsical Mirage Trampoline Harmony Aurora Firefly Ocean Radiance Singing Velvet Tranquility Galaxy Secret Trampoline Carnival Dancing Potion Horizon Apple Apple Echo Galaxy Velvet Moonlight Velvet Trampoline Radiance Euphoria Ocean Firefly Starlight Zephyr Mountain Cascade Firefly Tranquility',1,0.9,8980,'Alexander Henry','Matthew Alexander','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Velvet Whimsical','Secret Apple Thinking Carousel Serendipity Bamboo Trampoline Serenade Thinking Serendipity Secret Swimming Writing Mirage Saffron Enchantment Carousel Echo Serenade Mirage Tranquility Trampoline Whimsical Reading Apple Aurora Saffron Butterfly Moonlight Whisper Chocolate Dream Velvet Reading Piano Whisper Whimsical Mountain Rainbow Enchantment',24,19.2,1249,'Layla Lucas','Nova Isla','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Galaxy Treasure','Telescope Singing Butterfly Bamboo Velvet Carousel Bicycle Mirage Radiance Moonlight Dream Mystery Tranquility Potion Cascade Velvet Lighthouse Telescope Opulent Galaxy Serendipity Sunshine Jumping Tranquility Symphony Adventure Echo Cascade Bicycle Treasure Cascade Bicycle Sunshine Running Piano Horizon Bamboo Whimsical Treasure Enchantment',44,17.6,9653,'Luna Elizabeth','Sofia Ivy','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Firefly Quicksilver','Thinking Sleeping Reading Castle Aurora Reading Jumping Velvet Radiance Butterfly Mystery Velvet Carnival Dragon Aurora Lighthouse Adventure Adventure Opulent Mystery Radiance Serendipity Carousel Singing Trampoline Dragon Dragon Velvet Enchantment Swimming Thinking Enchantment Zephyr Reading Singing Butterfly Moonlight Telescope Cascade Reading',99,79.2,7901,'Scarlett Layla','Sophia Willow','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Telescope Thinking','Running Treasure Enchantment Carnival Lighthouse Velvet Saffron Zephyr Telescope Swimming Sunshine Starlight Reading Cascade Moonlight Sunshine Firefly Reading Chocolate Sleeping Elephant Swimming Aurora Opulent Castle Serenade Twilight Twilight Swimming Ocean Carnival Cascade Chocolate Butterfly Moonlight Carnival Enchantment Telescope Mystery Singing',14,2.799999999999999,7746,'Jayden Maya','Layla David','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Twilight Echo','Mystery Serendipity Dragon Writing Dragon Potion Sunshine Castle Quicksilver Serendipity Harmony Running Enchantment Starlight Galaxy Harmony Telescope Carousel Starlight Moonlight Trampoline Carousel Enchantment Swimming Radiance Eating Thinking Serendipity Ocean Piano Piano Quicksilver Dream Mountain Quicksilver Reading Firefly Cascade Velvet Adventure',56,14.0,8150,'Isla Isabella','Ezra Luna','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mirage Cascade Velvet','Velvet Tranquility Bamboo Opulent Opulent Radiance Running Singing Secret Trampoline Dragon Starlight Carnival Mirage Ocean Dream Running Radiance Serendipity Apple Swimming Secret Whimsical Mirage Apple Mirage Secret Mystery Running Butterfly Castle Bicycle Bicycle Trampoline Mirage Quicksilver Chocolate Thinking Velvet Apple',97,97,9266,'Santiago Matthew','Emma Asher','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mystery Running Harmony','Zephyr Enchantment Adventure Starlight Castle Potion Ocean Opulent Trampoline Whisper Dancing Reading Reading Bamboo Chocolate Lighthouse Potion Writing Running Mystery Jumping Treasure Whimsical Carnival Firefly Harmony Velvet Starlight Mystery Firefly Writing Singing Symphony Lighthouse Jumping Running Enchantment Dragon Eating Eating',53,13.25,175,'Luke Charlotte','Liam Santiago','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Echo Trampoline','Mountain Whimsical Serendipity Swimming Jumping Telescope Euphoria Adventure Firefly Zephyr Cascade Mountain Adventure Bicycle Symphony Mystery Reading Elephant Horizon Zephyr Saffron Euphoria Euphoria Firefly Opulent Firefly Bamboo Saffron Symphony Enchantment Carnival Butterfly Starlight Dancing Sleeping Chocolate Elephant Moonlight Swimming Horizon',82,20.5,7159,'Isla Ezekiel','Grayson Zoey','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Firefly Telescope','Serenade Reading Lighthouse Symphony Velvet Serenade Rainbow Cascade Jumping Telescope Tranquility Firefly Carnival Quicksilver Thinking Chocolate Saffron Opulent Chocolate Adventure Dream Mountain Enchantment Saffron Tranquility Symphony Echo Harmony Velvet Sunshine Butterfly Reading Whisper Rainbow Moonlight Dream Enchantment Dragon Velvet Butterfly',3,2.25,8017,'Samuel Hazel','James Ava','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Telescope Echo','Swimming Firefly Serendipity Tranquility Reading Mirage Dancing Chocolate Moonlight Serenade Thinking Serendipity Mirage Firefly Adventure Thinking Symphony Quicksilver Ocean Velvet Reading Reading Swimming Euphoria Writing Piano Trampoline Writing Eating Singing Secret Euphoria Treasure Jumping Carousel Bicycle Galaxy Starlight Sunshine Firefly',96,19.19999999999999,4268,'Jayden Levi','Elizabeth Hazel','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Sunshine Harmony','Velvet Zephyr Writing Mirage Symphony Echo Secret Lighthouse Writing Cascade Dancing Eating Butterfly Jumping Lighthouse Dancing Jumping Swimming Tranquility Singing Serenade Telescope Carousel Twilight Horizon Bicycle Horizon Eating Tranquility Butterfly Carnival Quicksilver Bicycle Carnival Carousel Euphoria Echo Mystery Lighthouse Jumping',91,81.9,448,'Benjamin Michael','Mateo Nora','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Apple Radiance','Running Piano Eating Symphony Serendipity Bicycle Radiance Whisper Sunshine Saffron Mountain Starlight Enchantment Radiance Dragon Mirage Dream Saffron Chocolate Writing Opulent Reading Trampoline Harmony Moonlight Dragon Firefly Chocolate Tranquility Sunshine Reading Swimming Trampoline Serenade Starlight Singing Telescope Whimsical Euphoria Enchantment',10,5.0,4417,'Elizabeth Hudson','Olivia Carter','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Jumping Eating Mirage','Velvet Thinking Mirage Moonlight Zephyr Velvet Symphony Thinking Aurora Firefly Apple Bamboo Chocolate Twilight Telescope Rainbow Carnival Quicksilver Butterfly Whisper Piano Eating Zephyr Galaxy Starlight Saffron Bamboo Mystery Reading Lighthouse Writing Harmony Saffron Secret Twilight Velvet Saffron Galaxy Reading Whimsical',76,68.4,6155,'Chloe Ezra','Matthew Mateo','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Singing Castle','Tranquility Radiance Velvet Enchantment Adventure Whimsical Euphoria Galaxy Running Ocean Butterfly Running Serendipity Starlight Bamboo Treasure Potion Trampoline Adventure Mystery Reading Carnival Apple Velvet Aurora Trampoline Ocean Quicksilver Bamboo Harmony Dragon Moonlight Thinking Sleeping Aurora Velvet Carousel Mystery Mountain Whimsical',34,17.0,4989,'Willow Matthew','Michael Amelia','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Echo Swimming Quicksilver','Writing Saffron Lighthouse Whisper Ocean Dream Singing Dancing Harmony Elephant Dancing Potion Swimming Radiance Zephyr Eating Opulent Whimsical Moonlight Serenade Sunshine Bicycle Velvet Adventure Chocolate Jumping Dream Treasure Secret Secret Firefly Sleeping Running Elephant Harmony Carousel Echo Butterfly Mystery Zephyr',30,12.0,904,'Ava Willow','Penelope Ezra','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Carousel Jumping','Moonlight Running Quicksilver Lighthouse Treasure Trampoline Chocolate Singing Quicksilver Trampoline Mountain Twilight Whisper Potion Apple Adventure Chocolate Twilight Chocolate Velvet Sunshine Mountain Carnival Radiance Horizon Serenade Lighthouse Adventure Mystery Trampoline Whisper Castle Butterfly Sleeping Carnival Telescope Trampoline Sleeping Apple Eating',90,81.0,9239,'Leilani Ivy','Asher Ellie','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Secret Butterfly','Elephant Mystery Starlight Moonlight Mystery Potion Dream Serendipity Harmony Whisper Castle Bicycle Starlight Aurora Carnival Aurora Galaxy Radiance Saffron Chocolate Quicksilver Dragon Saffron Enchantment Dragon Lighthouse Opulent Bicycle Tranquility Carnival Euphoria Enchantment Radiance Whisper Bicycle Euphoria Apple Ocean Velvet Firefly',74,37.0,5474,'Levi Maya','Avery Naomi','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Lighthouse Writing','Symphony Tranquility Eating Bicycle Piano Bamboo Firefly Dream Velvet Mystery Trampoline Zephyr Telescope Chocolate Running Mountain Starlight Echo Bamboo Moonlight Dragon Mystery Singing Mountain Adventure Velvet Firefly Zephyr Rainbow Dream Sunshine Dragon Echo Ocean Mountain Bamboo Bicycle Thinking Carnival Whimsical',76,60.8,3991,'Muhammad Gianna','Maverick Mateo','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dragon Whisper Echo','Whimsical Running Echo Mountain Aurora Ocean Galaxy Swimming Symphony Apple Enchantment Reading Moonlight Dragon Bicycle Quicksilver Potion Rainbow Chocolate Echo Eating Secret Butterfly Dancing Twilight Enchantment Symphony Jumping Firefly Ocean Tranquility Writing Galaxy Echo Eating Ocean Butterfly Euphoria Carnival Dancing',97,87.3,2364,'Ivy Avery','Emilia Avery','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Euphoria Ocean Trampoline','Ocean Trampoline Serendipity Enchantment Carousel Opulent Castle Piano Chocolate Bamboo Ocean Starlight Writing Opulent Potion Quicksilver Twilight Carnival Piano Thinking Quicksilver Telescope Sunshine Castle Apple Zephyr Dream Cascade Dream Ocean Chocolate Dancing Zephyr Dream Serendipity Potion Serendipity Mirage Telescope Radiance',40,40,2812,'Abigail Waylon','Josiah Kai','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Singing Trampoline Carousel','Serendipity Quicksilver Galaxy Dragon Potion Bicycle Cascade Ocean Elephant Jumping Velvet Tranquility Writing Radiance Carousel Elephant Piano Mystery Bamboo Mystery Potion Dancing Potion Saffron Moonlight Symphony Tranquility Dream Mountain Butterfly Writing Sleeping Singing Butterfly Telescope Thinking Apple Potion Radiance Telescope',67,26.800000000000004,5760,'Aiden Ella','Isabella Gianna','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Chocolate Treasure','Starlight Lighthouse Eating Bamboo Swimming Bamboo Singing Whisper Elephant Telescope Sleeping Velvet Thinking Twilight Elephant Swimming Mystery Euphoria Carnival Mountain Castle Sleeping Thinking Jumping Dream Dancing Symphony Eating Enchantment Thinking Opulent Bamboo Symphony Mountain Lighthouse Ocean Castle Twilight Euphoria Enchantment',79,19.75,3463,'Maverick Nova','Lily Luke','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Piano Thinking','Rainbow Trampoline Writing Enchantment Chocolate Saffron Mystery Singing Horizon Whisper Cascade Bicycle Lighthouse Twilight Writing Reading Enchantment Opulent Mirage Lighthouse Dragon Whisper Moonlight Whimsical Saffron Saffron Quicksilver Bicycle Harmony Writing Bicycle Eating Trampoline Rainbow Mountain Thinking Enchantment Radiance Tranquility Apple',24,18.0,4309,'Jack Ezra','Emily Chloe','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Treasure Firefly','Reading Echo Butterfly Whimsical Dancing Butterfly Mystery Moonlight Chocolate Enchantment Harmony Moonlight Writing Dream Piano Treasure Zephyr Echo Dream Potion Starlight Mountain Saffron Butterfly Sunshine Carousel Carnival Aurora Treasure Piano Horizon Telescope Galaxy Carousel Serenade Adventure Treasure Bicycle Echo Sleeping',42,21.0,5659,'Scarlett Lily','Lucas Evelyn','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Eating Trampoline','Symphony Serenade Thinking Symphony Elephant Velvet Apple Treasure Firefly Opulent Harmony Carnival Carnival Treasure Serendipity Starlight Dream Rainbow Velvet Tranquility Secret Horizon Rainbow Running Bicycle Whimsical Reading Lighthouse Sleeping Reading Serendipity Cascade Adventure Moonlight Saffron Dancing Rainbow Twilight Opulent Potion',97,72.75,6559,'Ivy Abigail','Ellie Mateo','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Swimming Horizon','Ocean Thinking Velvet Sunshine Symphony Dragon Jumping Harmony Horizon Aurora Aurora Jumping Dancing Galaxy Opulent Lighthouse Potion Running Galaxy Lighthouse Treasure Trampoline Aurora Opulent Radiance Apple Chocolate Dragon Apple Twilight Butterfly Whisper Quicksilver Whisper Chocolate Thinking Euphoria Dream Ocean Piano',73,73,3885,'Isaiah Ellie','Eleanor Luna','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Symphony Velvet Mirage','Euphoria Velvet Swimming Velvet Velvet Elephant Dream Twilight Sunshine Echo Chocolate Zephyr Apple Radiance Horizon Symphony Symphony Symphony Secret Trampoline Telescope Aurora Sunshine Symphony Mirage Mountain Reading Eating Writing Reading Butterfly Tranquility Twilight Dragon Velvet Rainbow Echo Ocean Firefly Twilight',64,12.799999999999997,7392,'Harper Layla','Zoey Grace','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Swimming Singing','Ocean Galaxy Firefly Firefly Bamboo Serendipity Dancing Jumping Horizon Thinking Quicksilver Whimsical Whisper Sunshine Serendipity Elephant Horizon Bamboo Jumping Treasure Sleeping Swimming Serenade Swimming Mystery Galaxy Potion Harmony Aurora Horizon Velvet Velvet Reading Carnival Serenade Harmony Treasure Symphony Opulent Euphoria',59,59,5540,'Ivy Riley','Sofia Layla','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Enchantment Running','Reading Piano Moonlight Velvet Thinking Cascade Radiance Serendipity Zephyr Chocolate Trampoline Dancing Enchantment Elephant Swimming Carousel Lighthouse Mountain Piano Mirage Apple Running Trampoline Rainbow Secret Echo Thinking Starlight Thinking Secret Aurora Mystery Dragon Harmony Harmony Chocolate Telescope Radiance Mirage Lighthouse',24,19.2,5786,'Mason Zoey','William Evelyn','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Saffron Rainbow','Harmony Running Euphoria Dancing Swimming Potion Twilight Reading Jumping Elephant Harmony Bamboo Twilight Thinking Galaxy Adventure Bicycle Euphoria Sleeping Galaxy Bicycle Chocolate Elephant Mystery Dancing Sunshine Castle Echo Butterfly Whimsical Bamboo Treasure Butterfly Treasure Starlight Mirage Velvet Symphony Elephant Treasure',3,0.5999999999999996,6229,'Wyatt Muhammad','Liam Delilah','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Saffron Bicycle Serenade','Singing Apple Apple Galaxy Sunshine Saffron Carnival Quicksilver Radiance Twilight Writing Apple Galaxy Velvet Echo Writing Velvet Rainbow Carousel Apple Dragon Castle Starlight Sleeping Symphony Velvet Serenade Sleeping Bicycle Moonlight Carnival Trampoline Firefly Dancing Swimming Eating Opulent Writing Aurora Singing',66,66,7381,'Maverick Miles','Jayden Levi','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Swimming Whimsical','Dream Apple Rainbow Treasure Mystery Castle Adventure Radiance Mountain Mirage Sunshine Adventure Zephyr Piano Quicksilver Dream Ocean Writing Singing Thinking Carousel Moonlight Secret Horizon Rainbow Serenade Telescope Zephyr Apple Apple Symphony Potion Mystery Rainbow Quicksilver Serendipity Swimming Symphony Secret Whimsical',70,28.0,4078,'Eliana Leo','Emilia Charlotte','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Jumping Elephant','Sleeping Bicycle Ocean Opulent Firefly Starlight Carnival Treasure Opulent Bamboo Starlight Mountain Secret Jumping Ocean Adventure Zephyr Jumping Dream Secret Aurora Dancing Tranquility Mirage Potion Treasure Carnival Dream Horizon Potion Dragon Velvet Carnival Opulent Swimming Twilight Velvet Carnival Symphony Apple',17,4.25,5962,'Nova Chloe','Isla Lily','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Radiance Dream','Carousel Aurora Chocolate Velvet Harmony Elephant Singing Telescope Euphoria Singing Rainbow Tranquility Quicksilver Apple Ocean Galaxy Dancing Dream Radiance Moonlight Opulent Carousel Trampoline Euphoria Jumping Reading Aurora Elephant Castle Sleeping Serenade Cascade Mirage Rainbow Mirage Euphoria Whisper Bicycle Butterfly Serenade',19,14.25,1210,'David Jacob','Theo Isabella','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Swimming Moonlight Aurora','Harmony Dragon Velvet Jumping Symphony Ocean Zephyr Telescope Telescope Butterfly Serendipity Sleeping Potion Eating Running Chocolate Enchantment Potion Thinking Piano Eating Singing Thinking Aurora Mirage Eating Dragon Trampoline Velvet Bamboo Reading Quicksilver Rainbow Velvet Lighthouse Singing Treasure Whisper Singing Harmony',70,52.5,6378,'Liam Muhammad','Avery William','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Echo Rainbow','Echo Carnival Starlight Firefly Lighthouse Mystery Twilight Running Zephyr Chocolate Starlight Jumping Sunshine Velvet Adventure Twilight Dancing Whisper Sunshine Euphoria Writing Rainbow Eating Tranquility Mystery Euphoria Tranquility Sunshine Saffron Elephant Bamboo Potion Lighthouse Mystery Mystery Moonlight Firefly Mirage Castle Serenade',49,19.6,5041,'Ezra Penelope','Gianna Charlotte','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Butterfly Quicksilver Quicksilver','Velvet Running Dream Saffron Horizon Singing Mystery Twilight Dream Enchantment Jumping Jumping Mystery Bamboo Carousel Harmony Zephyr Echo Dancing Firefly Zephyr Running Apple Dragon Dragon Treasure Swimming Bamboo Lighthouse Euphoria Tranquility Lighthouse Trampoline Quicksilver Aurora Firefly Tranquility Firefly Galaxy Mirage',60,45.0,129,'Violet Athena','Hazel Ivy','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Sunshine Bicycle','Enchantment Writing Whimsical Mountain Carousel Moonlight Mystery Apple Treasure Lighthouse Serendipity Symphony Enchantment Serendipity Bicycle Mountain Adventure Running Reading Opulent Bamboo Reading Serendipity Dream Carnival Firefly Velvet Serendipity Piano Quicksilver Treasure Rainbow Zephyr Reading Twilight Velvet Zephyr Velvet Echo Mystery',68,13.599999999999994,9140,'Penelope Amelia','Ethan Jackson','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Mountain Enchantment','Opulent Galaxy Cascade Aurora Whisper Writing Eating Running Bamboo Sunshine Jumping Running Cascade Dream Singing Writing Bicycle Bicycle Enchantment Serenade Apple Castle Firefly Ocean Serenade Carousel Thinking Bamboo Serenade Zephyr Opulent Reading Ocean Piano Mystery Bamboo Apple Swimming Cascade Writing',80,40.0,6997,'David Olivia','Jayden Willow','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Aurora Butterfly Firefly','Thinking Firefly Swimming Quicksilver Swimming Aurora Reading Chocolate Velvet Serendipity Ocean Butterfly Mystery Elephant Mountain Mountain Dancing Twilight Running Quicksilver Bamboo Rainbow Opulent Apple Whisper Mystery Bicycle Dream Potion Enchantment Potion Rainbow Symphony Dancing Dragon Piano Serenade Secret Trampoline Echo',2,0.5,6408,'Chloe Waylon','Julian Scarlett','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Ocean Ocean Running','Tranquility Jumping Castle Radiance Echo Radiance Reading Opulent Secret Swimming Quicksilver Apple Whisper Horizon Radiance Dream Dragon Butterfly Velvet Velvet Radiance Sunshine Carousel Twilight Twilight Lighthouse Apple Lighthouse Tranquility Swimming Euphoria Jumping Running Bamboo Serendipity Horizon Serenade Bicycle Aurora Swimming',3,3,8524,'Henry Ezra','Jacob Elijah','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Galaxy Carnival Horizon','Thinking Reading Harmony Mirage Horizon Twilight Zephyr Jumping Lighthouse Carnival Bicycle Velvet Sunshine Enchantment Dream Firefly Sleeping Horizon Enchantment Starlight Whimsical Running Euphoria Potion Castle Euphoria Bamboo Mirage Firefly Apple Singing Castle Saffron Moonlight Tranquility Cascade Sleeping Lighthouse Mirage Telescope',11,2.1999999999999993,2669,'Evelyn Harper','Camila Grace','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whisper Thinking Opulent','Secret Secret Apple Horizon Secret Bamboo Echo Serendipity Horizon Harmony Secret Twilight Whisper Tranquility Horizon Dragon Horizon Treasure Thinking Euphoria Rainbow Jumping Saffron Firefly Bicycle Echo Jumping Treasure Zephyr Swimming Symphony Chocolate Reading Enchantment Galaxy Jumping Velvet Trampoline Secret Lighthouse',65,13.0,235,'Naomi Eliana','Levi Amelia','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Rainbow Twilight Trampoline','Echo Serendipity Mystery Zephyr Saffron Symphony Whimsical Telescope Starlight Euphoria Quicksilver Cascade Treasure Enchantment Apple Sleeping Adventure Sunshine Horizon Galaxy Galaxy Whisper Running Mirage Whisper Castle Mountain Echo Bamboo Firefly Secret Trampoline Lighthouse Jumping Running Velvet Butterfly Piano Dream Harmony',20,15.0,2384,'Willow Avery','Jacob Logan','Turkish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Lighthouse Dancing Thinking','Chocolate Treasure Ocean Horizon Apple Tranquility Carousel Sunshine Dragon Castle Sunshine Bamboo Dream Velvet Lighthouse Piano Swimming Velvet Elephant Moonlight Velvet Castle Dragon Velvet Starlight Trampoline Enchantment Dragon Chocolate Firefly Singing Zephyr Enchantment Reading Rainbow Running Saffron Firefly Elephant Starlight',81,40.5,3850,'Nora Zoe','Asher Michael','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Apple Whisper','Dream Moonlight Rainbow Saffron Galaxy Whimsical Apple Serendipity Thinking Dancing Horizon Galaxy Swimming Carnival Dragon Symphony Potion Swimming Galaxy Chocolate Firefly Jumping Chocolate Twilight Butterfly Piano Eating Dancing Mountain Cascade Firefly Serenade Treasure Enchantment Quicksilver Writing Swimming Bicycle Adventure Quicksilver',27,6.75,7448,'Josiah Ethan','Nova Ava','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Firefly Serenade','Writing Bicycle Horizon Starlight Enchantment Jumping Horizon Mirage Telescope Sleeping Running Apple Aurora Bicycle Eating Tranquility Elephant Ocean Radiance Starlight Serenade Velvet Moonlight Starlight Reading Secret Radiance Apple Bicycle Trampoline Ocean Rainbow Enchantment Saffron Dragon Firefly Singing Velvet Echo Whisper',14,14,289,'Delilah Owen','Leilani Olivia','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Mirage Velvet Carnival','Dragon Mountain Whimsical Bicycle Apple Cascade Symphony Dream Running Serendipity Lighthouse Horizon Thinking Trampoline Dragon Piano Trampoline Swimming Swimming Ocean Opulent Cascade Velvet Adventure Velvet Radiance Aurora Sunshine Symphony Horizon Potion Quicksilver Treasure Singing Opulent Carousel Sleeping Elephant Secret Serenade',27,13.5,5415,'Elizabeth William','Olivia Oliver','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Twilight Telescope','Castle Twilight Horizon Echo Thinking Singing Enchantment Eating Velvet Mystery Firefly Zephyr Firefly Dream Cascade Ocean Piano Butterfly Twilight Bamboo Euphoria Velvet Singing Echo Adventure Harmony Mystery Saffron Dream Piano Firefly Euphoria Jumping Twilight Singing Moonlight Enchantment Reading Ocean Starlight',39,31.2,2823,'Lily Wyatt','Ella Muhammad','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Telescope Bamboo Mystery','Writing Singing Twilight Serendipity Starlight Dream Moonlight Velvet Castle Sunshine Symphony Saffron Bicycle Radiance Eating Saffron Lighthouse Potion Potion Saffron Jumping Singing Mountain Castle Swimming Adventure Velvet Bicycle Trampoline Reading Lighthouse Serendipity Rainbow Running Opulent Mountain Apple Starlight Running Telescope',82,61.5,1155,'Waylon Ivy','Maverick Theodore','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Velvet Lighthouse','Carnival Thinking Zephyr Serendipity Carousel Bamboo Castle Opulent Aurora Sunshine Serendipity Thinking Harmony Eating Running Rainbow Mountain Apple Firefly Jumping Elephant Serendipity Saffron Singing Eating Sunshine Starlight Trampoline Mountain Jumping Swimming Moonlight Jumping Whisper Carnival Twilight Castle Running Lighthouse Starlight',76,30.4,6313,'Theo Matthew','Mateo Maya','Telugu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Thinking Opulent','Jumping Velvet Symphony Singing Zephyr Bamboo Galaxy Starlight Mirage Carnival Horizon Singing Singing Symphony Velvet Galaxy Dream Potion Treasure Treasure Trampoline Carnival Eating Whimsical Mystery Mystery Radiance Mountain Singing Serenade Symphony Rainbow Lighthouse Harmony Singing Potion Opulent Swimming Writing Sunshine',58,58,5324,'Emma Muhammad','Gianna Olivia','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Treasure Jumping','Whisper Sunshine Zephyr Twilight Carousel Carnival Jumping Potion Echo Butterfly Elephant Dancing Trampoline Tranquility Secret Apple Mystery Quicksilver Velvet Bamboo Moonlight Opulent Mystery Moonlight Harmony Thinking Horizon Starlight Piano Piano Velvet Aurora Serendipity Euphoria Chocolate Castle Dragon Ocean Aurora Radiance',90,67.5,4044,'Lily Maya','Sophia Charlotte','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Mountain Swimming','Carnival Treasure Castle Running Reading Eating Piano Enchantment Swimming Thinking Velvet Mountain Mirage Serendipity Telescope Castle Moonlight Bicycle Castle Zephyr Serenade Ocean Symphony Velvet Singing Rainbow Lighthouse Starlight Velvet Tranquility Ocean Reading Firefly Opulent Whimsical Bamboo Serenade Secret Potion Eating',46,34.5,836,'Matthew Logan','Gabriel Ella','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Dream Adventure','Mirage Galaxy Dragon Butterfly Serendipity Harmony Harmony Carousel Potion Whisper Writing Potion Bicycle Reading Trampoline Singing Galaxy Reading Dream Horizon Sunshine Castle Velvet Secret Butterfly Mystery Whisper Swimming Enchantment Zephyr Velvet Dream Apple Telescope Opulent Apple Carousel Bamboo Opulent Symphony',17,8.5,6244,'Elena Grayson','Mason Grace','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Piano Twilight','Rainbow Symphony Euphoria Sleeping Carousel Horizon Telescope Starlight Firefly Bamboo Swimming Moonlight Harmony Dancing Telescope Horizon Velvet Running Cascade Velvet Carnival Piano Velvet Dancing Echo Running Singing Swimming Swimming Telescope Radiance Velvet Whimsical Chocolate Galaxy Saffron Serendipity Treasure Velvet Mirage',1,0.75,5213,'Lucas Luca','Luna Jacob','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Adventure Opulent Starlight','Chocolate Opulent Treasure Carnival Firefly Rainbow Symphony Serenade Dragon Echo Mountain Bamboo Firefly Jumping Running Piano Velvet Mirage Moonlight Whisper Whimsical Harmony Velvet Elephant Piano Adventure Carnival Moonlight Dragon Cascade Potion Dream Zephyr Enchantment Butterfly Rainbow Opulent Castle Castle Starlight',32,28.8,8874,'Julian Kai','Emilia Mia','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sleeping Mystery Echo','Velvet Cascade Aurora Sunshine Carnival Dream Firefly Dancing Castle Swimming Apple Mirage Radiance Trampoline Horizon Elephant Writing Rainbow Serendipity Serenade Mountain Opulent Mirage Potion Mystery Starlight Whisper Elephant Writing Writing Serendipity Secret Starlight Symphony Moonlight Euphoria Sleeping Serenade Ocean Cascade',76,19.0,6334,'Santiago Scarlett','Jacob Emily','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Running Starlight','Zephyr Eating Singing Tranquility Singing Opulent Symphony Writing Cascade Tranquility Castle Apple Quicksilver Rainbow Symphony Butterfly Dream Mirage Whimsical Serendipity Radiance Mirage Euphoria Serendipity Swimming Symphony Quicksilver Velvet Tranquility Secret Sunshine Zephyr Euphoria Twilight Saffron Serenade Potion Euphoria Symphony Elephant',95,95,5650,'Asher Luca','Mila Lily','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Opulent Lighthouse Potion','Trampoline Writing Euphoria Enchantment Dragon Dragon Mirage Enchantment Elephant Serenade Harmony Writing Rainbow Apple Quicksilver Dragon Enchantment Castle Opulent Running Serenade Elephant Echo Symphony Horizon Butterfly Secret Dragon Reading Cascade Mystery Secret Treasure Quicksilver Radiance Potion Zephyr Potion Running Twilight',47,35.25,1012,'Samuel Riley','Olivia Maverick','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Opulent Piano','Serendipity Velvet Bamboo Adventure Chocolate Firefly Whimsical Serenade Moonlight Symphony Cascade Potion Echo Firefly Swimming Dream Jumping Tranquility Treasure Twilight Bamboo Bamboo Starlight Mystery Symphony Swimming Enchantment Ocean Piano Galaxy Piano Chocolate Dancing Galaxy Velvet Piano Writing Enchantment Dancing Mirage',21,8.4,5543,'Carter Hudson','Liam Josiah','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Apple Butterfly','Bicycle Firefly Euphoria Mystery Apple Mirage Symphony Whisper Saffron Trampoline Dancing Euphoria Bamboo Lighthouse Ocean Quicksilver Mystery Aurora Mystery Tranquility Radiance Rainbow Carnival Echo Treasure Dragon Sunshine Carousel Mountain Trampoline Velvet Tranquility Jumping Writing Mountain Elephant Swimming Quicksilver Sunshine Apple',6,1.1999999999999993,5935,'Hudson Theo','Michael Olivia','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Swimming Horizon Galaxy','Serenade Swimming Galaxy Firefly Mystery Whimsical Writing Horizon Swimming Lighthouse Bamboo Sleeping Telescope Piano Dream Starlight Castle Swimming Velvet Enchantment Mountain Thinking Horizon Harmony Writing Bamboo Adventure Horizon Aurora Euphoria Mystery Apple Cascade Dancing Potion Whimsical Trampoline Sleeping Dancing Serenade',100,25.0,8866,'Henry Aurora','Liam Emma','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Echo Serendipity Trampoline','Serendipity Enchantment Cascade Twilight Thinking Dancing Treasure Elephant Carnival Mountain Chocolate Swimming Secret Writing Velvet Echo Sunshine Symphony Dancing Cascade Tranquility Potion Serenade Bicycle Harmony Running Velvet Whisper Serenade Whimsical Ocean Velvet Velvet Singing Sunshine Euphoria Castle Swimming Tranquility Velvet',23,18.4,9230,'Nova Paisley','Riley Elena','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Trampoline Cascade Bamboo','Eating Serendipity Quicksilver Secret Galaxy Treasure Mirage Mirage Chocolate Dragon Rainbow Serendipity Euphoria Castle Writing Thinking Whimsical Adventure Cascade Serendipity Apple Reading Adventure Whisper Singing Enchantment Rainbow Enchantment Mountain Secret Radiance Starlight Carnival Reading Zephyr Mountain Running Dragon Velvet Tranquility',47,11.75,8177,'Athena Avery','Eleanor Avery','Marathi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Reading Serenade','Euphoria Piano Butterfly Serendipity Bicycle Quicksilver Thinking Sleeping Twilight Cascade Eating Whisper Singing Mystery Firefly Quicksilver Swimming Tranquility Castle Apple Whimsical Whisper Velvet Saffron Carnival Apple Piano Horizon Adventure Serendipity Tranquility Serenade Bicycle Velvet Cascade Echo Euphoria Apple Velvet Apple',8,6.4,7977,'Mia Sebastian','Kai Leo','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Aurora Mirage','Firefly Serendipity Apple Harmony Running Opulent Mystery Potion Lighthouse Starlight Dancing Adventure Apple Chocolate Horizon Whimsical Adventure Harmony Bamboo Butterfly Mystery Ocean Potion Firefly Velvet Twilight Piano Mystery Radiance Quicksilver Adventure Aurora Reading Mountain Mystery Firefly Writing Euphoria Galaxy Velvet',39,29.25,8600,'Leo Grayson','Willow Muhammad','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bicycle Writing Eating','Swimming Horizon Whimsical Velvet Trampoline Moonlight Potion Galaxy Starlight Moonlight Lighthouse Secret Horizon Chocolate Tranquility Velvet Piano Firefly Echo Whisper Swimming Secret Starlight Potion Velvet Whimsical Starlight Telescope Echo Firefly Lighthouse Elephant Carnival Dragon Velvet Enchantment Aurora Whisper Jumping Bicycle',97,97,198,'Harper Luna','Charlotte James','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Elephant Singing Bicycle','Whimsical Potion Moonlight Carousel Opulent Mountain Dancing Harmony Jumping Aurora Saffron Opulent Trampoline Dream Lighthouse Saffron Dragon Elephant Velvet Ocean Adventure Euphoria Castle Piano Rainbow Carnival Singing Zephyr Radiance Lighthouse Opulent Bamboo Dancing Eating Galaxy Horizon Velvet Chocolate Whimsical Singing',57,22.800000000000004,8302,'Jacob Riley','Mason Muhammad','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dancing Euphoria Twilight','Enchantment Saffron Castle Chocolate Euphoria Dancing Opulent Bamboo Secret Horizon Aurora Writing Echo Harmony Mystery Cascade Harmony Quicksilver Euphoria Euphoria Cascade Ocean Horizon Saffron Lighthouse Secret Bicycle Harmony Euphoria Potion Quicksilver Whisper Piano Starlight Euphoria Ocean Potion Velvet Whisper Mystery',22,19.8,6211,'Zoe Levi','Zoey Sofia','Chinese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Dream Euphoria','Aurora Writing Horizon Galaxy Firefly Dragon Carnival Bamboo Starlight Piano Velvet Apple Opulent Horizon Ocean Radiance Euphoria Sleeping Moonlight Zephyr Butterfly Secret Enchantment Twilight Tranquility Serenade Eating Whisper Elephant Potion Velvet Carousel Swimming Sleeping Enchantment Serenade Saffron Dancing Symphony Cascade',71,63.9,5015,'Luna James','Emma Emilia','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Opulent Potion','Rainbow Mirage Bicycle Ocean Ocean Horizon Opulent Secret Lighthouse Carousel Opulent Jumping Mystery Mirage Quicksilver Writing Rainbow Jumping Twilight Butterfly Whisper Harmony Bicycle Thinking Velvet Elephant Euphoria Quicksilver Mirage Euphoria Jumping Bicycle Serendipity Quicksilver Potion Sleeping Tranquility Apple Piano Carousel',37,7.399999999999999,5757,'Lily Zoey','Jackson Camila','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Radiance Saffron','Carousel Euphoria Tranquility Castle Whimsical Chocolate Carousel Piano Saffron Zephyr Zephyr Bicycle Elephant Potion Piano Trampoline Potion Swimming Thinking Starlight Saffron Castle Treasure Piano Moonlight Firefly Enchantment Mirage Running Dream Jumping Elephant Firefly Sunshine Bicycle Serenade Tranquility Zephyr Castle Harmony',68,13.599999999999994,9696,'Avery Amelia','Jacob Carter','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Castle Serenade Starlight','Symphony Carousel Piano Mirage Dragon Bamboo Butterfly Euphoria Elephant Swimming Saffron Whisper Thinking Zephyr Ocean Whimsical Aurora Velvet Carnival Moonlight Galaxy Writing Lighthouse Firefly Treasure Radiance Saffron Opulent Carnival Trampoline Running Jumping Elephant Apple Treasure Treasure Lighthouse Adventure Cascade Zephyr',87,21.75,5894,'Nova Naomi','Leo Ezekiel','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Apple Carousel','Galaxy Mystery Running Carnival Telescope Whimsical Horizon Enchantment Reading Dragon Swimming Enchantment Mountain Carnival Zephyr Castle Quicksilver Zephyr Moonlight Chocolate Eating Euphoria Dancing Castle Bicycle Thinking Harmony Moonlight Radiance Writing Euphoria Adventure Mountain Dancing Piano Symphony Quicksilver Whisper Mountain Serendipity',30,7.5,1252,'Leilani Jack','Mason Emily','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dream Adventure Ocean','Saffron Chocolate Castle Twilight Carnival Bicycle Reading Elephant Sunshine Whisper Starlight Mirage Castle Horizon Potion Butterfly Velvet Jumping Dream Treasure Whisper Twilight Ocean Whisper Galaxy Elephant Galaxy Velvet Symphony Rainbow Mystery Bicycle Zephyr Whisper Bamboo Starlight Whimsical Lighthouse Jumping Enchantment',81,60.75,7264,'Chloe Matthew','Sofia Athena','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Twilight Ocean Cascade','Bicycle Enchantment Rainbow Elephant Opulent Eating Castle Mountain Castle Velvet Euphoria Firefly Serenade Radiance Firefly Butterfly Reading Treasure Quicksilver Trampoline Echo Apple Writing Aurora Carnival Elephant Opulent Adventure Dream Whimsical Writing Velvet Piano Horizon Bicycle Eating Saffron Bamboo Sunshine Swimming',89,22.25,3115,'Aurora Matthew','Theodore Josiah','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Telescope Symphony Sunshine','Dancing Dancing Chocolate Treasure Carnival Carousel Telescope Horizon Potion Euphoria Cascade Lighthouse Whisper Bamboo Bamboo Serendipity Serendipity Dream Twilight Castle Aurora Firefly Secret Mirage Tranquility Horizon Treasure Galaxy Piano Bicycle Whimsical Castle Dragon Whimsical Zephyr Dancing Eating Writing Dancing Dragon',39,29.25,1499,'Avery Isla','Mia Riley','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Treasure Trampoline Potion','Radiance Bicycle Enchantment Firefly Saffron Writing Twilight Echo Telescope Mountain Rainbow Galaxy Treasure Carousel Velvet Writing Telescope Swimming Elephant Saffron Whimsical Bamboo Castle Echo Butterfly Serendipity Quicksilver Adventure Whimsical Butterfly Carnival Swimming Dream Castle Zephyr Moonlight Apple Apple Piano Mirage',19,14.25,8850,'Delilah Emily','Jackson William','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Eating Sunshine','Opulent Tranquility Sunshine Velvet Potion Whisper Carousel Firefly Castle Euphoria Apple Horizon Serenade Moonlight Symphony Thinking Zephyr Reading Ocean Moonlight Running Euphoria Lighthouse Opulent Twilight Singing Starlight Mirage Dragon Bamboo Radiance Carnival Swimming Potion Tranquility Tranquility Reading Carnival Serenade Quicksilver',71,71,5395,'Daniel Ellie','Benjamin Willow','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bamboo Opulent Apple','Chocolate Secret Apple Dream Mountain Carnival Galaxy Opulent Saffron Secret Symphony Quicksilver Reading Radiance Reading Sleeping Carnival Reading Castle Elephant Butterfly Whisper Lighthouse Eating Carousel Horizon Mountain Elephant Trampoline Secret Mystery Opulent Whisper Dream Castle Firefly Zephyr Eating Adventure Butterfly',44,17.6,7000,'Mia Abigail','Scarlett Benjamin','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Eating Horizon','Ocean Echo Cascade Elephant Zephyr Ocean Symphony Ocean Starlight Enchantment Singing Elephant Rainbow Velvet Ocean Writing Twilight Velvet Symphony Whisper Horizon Running Lighthouse Carousel Castle Dancing Lighthouse Whimsical Saffron Dragon Piano Treasure Mountain Elephant Carnival Velvet Radiance Swimming Whimsical Mirage',34,25.5,7664,'Oliver Harper','Alexander Alexander','Hindi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Quicksilver Lighthouse Eating','Bicycle Carousel Sunshine Twilight Carousel Treasure Moonlight Echo Opulent Treasure Dream Sleeping Serendipity Running Singing Twilight Symphony Castle Quicksilver Twilight Aurora Tranquility Mystery Mountain Telescope Twilight Cascade Telescope Dancing Moonlight Sleeping Mountain Horizon Harmony Symphony Eating Carousel Whimsical Butterfly Carnival',24,12.0,2783,'Grace Santiago','Miles Elijah','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Eating Opulent Mountain','Treasure Ocean Mountain Saffron Opulent Opulent Treasure Chocolate Firefly Thinking Adventure Adventure Dream Reading Bamboo Castle Treasure Sleeping Mirage Whisper Serenade Apple Bicycle Radiance Moonlight Starlight Swimming Serendipity Rainbow Castle Adventure Enchantment Aurora Thinking Adventure Saffron Whisper Symphony Whimsical Velvet',62,49.6,6769,'Luca Chloe','Daniel Leo','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Running Firefly Radiance','Mountain Twilight Sunshine Cascade Rainbow Apple Thinking Horizon Bicycle Dream Trampoline Treasure Sunshine Symphony Lighthouse Mirage Starlight Thinking Adventure Butterfly Treasure Bicycle Secret Butterfly Bicycle Velvet Dancing Radiance Cascade Eating Aurora Carnival Telescope Eating Chocolate Eating Swimming Quicksilver Harmony Chocolate',41,30.75,5359,'Noah Amelia','William Jack','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Ocean Elephant Firefly','Harmony Chocolate Bamboo Mountain Bamboo Symphony Swimming Castle Potion Dragon Tranquility Starlight Thinking Mirage Bamboo Firefly Galaxy Telescope Apple Serendipity Trampoline Reading Galaxy Treasure Telescope Firefly Swimming Elephant Adventure Enchantment Euphoria Enchantment Euphoria Zephyr Singing Dragon Aurora Moonlight Opulent Castle',88,79.2,5846,'Zoe Aurora','Isaiah Waylon','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Bicycle Saffron','Thinking Dragon Velvet Butterfly Swimming Mystery Singing Symphony Adventure Elephant Ocean Aurora Jumping Jumping Sleeping Saffron Mirage Elephant Mountain Tranquility Singing Moonlight Radiance Horizon Running Reading Horizon Dancing Trampoline Starlight Twilight Galaxy Saffron Bicycle Symphony Carousel Mirage Cascade Velvet Jumping',58,58,717,'Asher Athena','Theodore David','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Castle Rainbow','Cascade Castle Sleeping Rainbow Opulent Tranquility Horizon Jumping Whisper Cascade Ocean Castle Carnival Piano Saffron Elephant Horizon Opulent Dancing Sunshine Jumping Dream Sunshine Whisper Sunshine Running Enchantment Twilight Twilight Horizon Horizon Lighthouse Serendipity Sleeping Tranquility Reading Horizon Carnival Dragon Dancing',92,18.39999999999999,9123,'Delilah Isabella','Sofia Ella','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Opulent Elephant Mountain','Bamboo Saffron Treasure Enchantment Carnival Castle Piano Potion Moonlight Carnival Sunshine Dragon Ocean Lighthouse Dream Harmony Starlight Potion Sleeping Velvet Carousel Jumping Enchantment Zephyr Horizon Castle Quicksilver Twilight Zephyr Tranquility Symphony Starlight Ocean Secret Dragon Eating Treasure Whimsical Telescope Bamboo',46,18.400000000000002,6082,'Zoey Oliver','Sophia Elena','Russian');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Harmony Running Enchantment','Whimsical Adventure Adventure Elephant Sunshine Treasure Mystery Telescope Serenade Serendipity Eating Carousel Butterfly Butterfly Piano Trampoline Secret Eating Piano Bamboo Running Thinking Radiance Tranquility Piano Reading Saffron Rainbow Starlight Velvet Treasure Bicycle Adventure Potion Chocolate Velvet Dream Ocean Secret Quicksilver',58,58,8398,'Avery Logan','David Henry','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Swimming Thinking Dragon','Horizon Euphoria Castle Mountain Bamboo Eating Swimming Aurora Eating Euphoria Lighthouse Dream Adventure Trampoline Zephyr Galaxy Mirage Galaxy Opulent Dragon Reading Whimsical Dancing Opulent Secret Twilight Butterfly Velvet Dancing Ocean Thinking Rainbow Tranquility Starlight Galaxy Mystery Moonlight Singing Tranquility Telescope',25,10.0,9409,'Violet Emma','Zoey Hazel','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Thinking Euphoria Symphony','Dragon Running Bicycle Carousel Mystery Secret Reading Tranquility Lighthouse Symphony Lighthouse Trampoline Treasure Velvet Elephant Euphoria Bamboo Serendipity Dragon Bamboo Radiance Quicksilver Echo Dream Moonlight Adventure Eating Euphoria Thinking Adventure Opulent Horizon Quicksilver Enchantment Rainbow Galaxy Sunshine Eating Whisper Aurora',12,12,873,'Madison Gabriel','Sebastian Carter','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Velvet Running','Twilight Thinking Bamboo Reading Piano Saffron Apple Firefly Aurora Sunshine Symphony Castle Elephant Sunshine Swimming Cascade Galaxy Bamboo Eating Whisper Serendipity Horizon Radiance Bicycle Lighthouse Adventure Bamboo Rainbow Saffron Chocolate Euphoria Treasure Velvet Apple Butterfly Reading Castle Starlight Carnival Thinking',20,20,927,'Aria Carter','Evelyn Carter','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Moonlight Cascade Reading','Euphoria Mirage Thinking Bamboo Potion Symphony Whimsical Zephyr Dancing Sunshine Firefly Sunshine Reading Lighthouse Mountain Butterfly Mystery Telescope Firefly Moonlight Butterfly Running Lighthouse Butterfly Saffron Dream Whimsical Lighthouse Harmony Bamboo Adventure Mirage Mystery Serendipity Quicksilver Quicksilver Sleeping Adventure Eating Lighthouse',90,36.0,6439,'Evelyn Zoey','Mila Ezra','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Zephyr Aurora Ocean','Writing Mystery Serendipity Butterfly Dragon Sleeping Starlight Lighthouse Ocean Symphony Ocean Writing Jumping Sleeping Whimsical Starlight Dragon Piano Aurora Dancing Dancing Symphony Elephant Treasure Symphony Bamboo Whimsical Saffron Firefly Horizon Mirage Quicksilver Galaxy Sunshine Jumping Butterfly Potion Sleeping Opulent Secret',23,18.4,7552,'Ellie Penelope','Ellie Asher','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Radiance Dream','Chocolate Whimsical Echo Cascade Mystery Dream Carnival Chocolate Dream Chocolate Radiance Writing Chocolate Whisper Bicycle Carousel Starlight Zephyr Bicycle Lighthouse Rainbow Cascade Opulent Quicksilver Elephant Lighthouse Mystery Mountain Firefly Twilight Singing Symphony Mystery Velvet Harmony Velvet Bamboo Ocean Secret Quicksilver',11,8.8,1983,'Paisley Kai','Abigail Mia','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Velvet Firefly Piano','Symphony Tranquility Saffron Jumping Saffron Trampoline Carnival Carnival Adventure Whisper Running Enchantment Running Rainbow Moonlight Enchantment Swimming Swimming Bicycle Whimsical Chocolate Reading Mirage Dream Dancing Radiance Twilight Potion Bicycle Eating Quicksilver Chocolate Serendipity Tranquility Symphony Castle Symphony Tranquility Secret Twilight',51,20.400000000000002,7563,'Ezra Madison','Elizabeth Miles','Urdu');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Dragon Thinking Trampoline','Butterfly Mirage Carousel Apple Symphony Chocolate Saffron Mystery Castle Reading Quicksilver Horizon Carnival Writing Thinking Singing Saffron Dream Moonlight Harmony Trampoline Harmony Thinking Writing Mirage Symphony Jumping Whisper Bicycle Mystery Apple Swimming Treasure Mountain Echo Dream Mirage Echo Bamboo Sunshine',1,0.9,3936,'Athena Muhammad','Mateo Gabriel','Arabic');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Cascade Sleeping','Running Quicksilver Quicksilver Sleeping Dream Chocolate Telescope Jumping Euphoria Bamboo Harmony Trampoline Twilight Writing Starlight Bamboo Opulent Ocean Horizon Whisper Whimsical Ocean Serendipity Lighthouse Velvet Moonlight Running Thinking Dream Cascade Opulent Starlight Trampoline Castle Radiance Firefly Piano Galaxy Carousel Quicksilver',89,71.2,3461,'Paisley Mason','Maverick Henry','Japanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Chocolate Whisper Eating','Velvet Echo Dragon Zephyr Mystery Bicycle Ocean Saffron Chocolate Trampoline Dragon Velvet Sleeping Butterfly Chocolate Telescope Mystery Whimsical Trampoline Cascade Trampoline Twilight Serenade Rainbow Whisper Apple Galaxy Trampoline Zephyr Castle Bicycle Tranquility Secret Tranquility Tranquility Velvet Singing Sunshine Twilight Potion',68,13.599999999999994,9424,'Avery James','Carter Olivia','French');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Whimsical Sleeping Radiance','Starlight Radiance Starlight Radiance Carousel Serendipity Bamboo Radiance Telescope Apple Eating Cascade Quicksilver Symphony Chocolate Moonlight Mystery Mountain Saffron Writing Whisper Elephant Mystery Piano Castle Bamboo Adventure Galaxy Elephant Mountain Running Moonlight Chocolate Running Carousel Adventure Symphony Opulent Enchantment Ocean',47,42.3,6531,'Zoey Naomi','Maverick Elias','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Horizon Rainbow Dragon','Echo Mystery Harmony Trampoline Twilight Dream Piano Elephant Echo Echo Tranquility Lighthouse Writing Velvet Serenade Jumping Writing Reading Running Carousel Twilight Aurora Quicksilver Euphoria Euphoria Serenade Writing Jumping Telescope Serenade Writing Whisper Zephyr Harmony Castle Cascade Galaxy Elephant Adventure Trampoline',78,39.0,630,'Alexander Gianna','Mateo Mila','Spanish');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Enchantment Mountain Adventure','Apple Thinking Running Lighthouse Treasure Mountain Mystery Twilight Whimsical Serenade Sunshine Mystery Ocean Chocolate Aurora Euphoria Euphoria Eating Saffron Rainbow Serenade Quicksilver Velvet Running Butterfly Jumping Elephant Running Dragon Eating Dragon Rainbow Echo Dancing Dragon Castle Rainbow Cascade Twilight Jumping',74,55.5,5298,'Willow Theo','Hazel Emily','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Carnival Whimsical Cascade','Velvet Potion Singing Mirage Jumping Radiance Bamboo Symphony Velvet Adventure Reading Euphoria Sleeping Echo Adventure Cascade Mirage Zephyr Carousel Whimsical Twilight Telescope Mirage Enchantment Tranquility Serendipity Apple Treasure Apple Piano Firefly Horizon Enchantment Firefly Jumping Dancing Harmony Elephant Moonlight Mirage',7,5.6,7547,'Ava Riley','Logan Abigail','Javanese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Potion Serenade Chocolate','Jumping Chocolate Mystery Serendipity Serendipity Starlight Cascade Telescope Horizon Carousel Moonlight Lighthouse Reading Ocean Lighthouse Horizon Lighthouse Secret Zephyr Cascade Sleeping Dragon Chocolate Thinking Bicycle Euphoria Twilight Running Castle Ocean Whisper Serenade Harmony Euphoria Whisper Opulent Whimsical Serendipity Sunshine Butterfly',89,44.5,3153,'Owen Ezra','Aurora Josiah','English');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Sunshine Writing Firefly','Quicksilver Elephant Moonlight Writing Cascade Ocean Trampoline Jumping Dancing Writing Swimming Secret Velvet Trampoline Symphony Quicksilver Eating Secret Radiance Firefly Bicycle Lighthouse Eating Writing Galaxy Dream Aurora Swimming Telescope Twilight Carousel Bicycle Serendipity Castle Harmony Butterfly Dragon Sunshine Quicksilver Potion',65,32.5,2628,'Wyatt Paisley','Jayden Isla','Vietnamese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Bamboo Dancing Trampoline','Jumping Opulent Reading Harmony Reading Reading Bamboo Carnival Firefly Serenade Moonlight Twilight Harmony Cascade Ocean Swimming Whimsical Adventure Swimming Dragon Thinking Tranquility Velvet Sunshine Running Starlight Bicycle Apple Harmony Firefly Tranquility Running Mystery Eating Enchantment Chocolate Bicycle Symphony Treasure Galaxy',39,7.799999999999997,1996,'Maya Ezekiel','Aria Gianna','Bengali');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Echo Reading Galaxy','Potion Jumping Treasure Serendipity Carousel Eating Sleeping Cascade Velvet Singing Chocolate Galaxy Mystery Horizon Secret Carnival Mountain Trampoline Lighthouse Ocean Eating Treasure Carnival Whimsical Tranquility Eating Saffron Mystery Whisper Opulent Bicycle Symphony Echo Dream Bamboo Mountain Singing Sunshine Velvet Serenade',24,19.2,3306,'Matthew Josiah','Noah Ellie','Punjabi');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Reading Castle Secret','Potion Chocolate Bicycle Cascade Quicksilver Bamboo Writing Treasure Moonlight Dragon Lighthouse Firefly Swimming Whisper Swimming Eating Whimsical Ocean Serenade Opulent Dancing Mirage Mystery Twilight Mystery Starlight Running Mystery Whisper Zephyr Eating Moonlight Swimming Dream Trampoline Piano Jumping Galaxy Bicycle Serendipity',40,40,8645,'Jayden Elias','Kai Sophia','German');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Echo Lighthouse Writing','Starlight Carnival Harmony Galaxy Twilight Whisper Ocean Jumping Serenade Tranquility Aurora Sleeping Bicycle Eating Apple Aurora Starlight Saffron Serenade Potion Harmony Enchantment Euphoria Radiance Secret Twilight Dancing Telescope Mystery Bamboo Telescope Dancing Ocean Writing Opulent Treasure Whisper Tranquility Whimsical Apple',93,93,1728,'Waylon Levi','Waylon Ivy','Tamil');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Serendipity Radiance Lighthouse','Zephyr Serenade Bicycle Tranquility Opulent Trampoline Quicksilver Twilight Horizon Harmony Adventure Jumping Swimming Treasure Telescope Bicycle Harmony Castle Starlight Dream Twilight Serenade Dragon Elephant Sunshine Thinking Firefly Writing Swimming Sunshine Starlight Firefly Opulent Carousel Dream Twilight Carnival Apple Chocolate Starlight',2,0.5,2123,'Paisley Hazel','Asher Luke','Portuguese');
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES('Secret Elephant Rainbow','Dragon Cascade Harmony Jumping Telescope Horizon Harmony Treasure Zephyr Dream Serenade Bamboo Bicycle Carnival Eating Sleeping Secret Aurora Radiance Ocean Rainbow Mystery Whisper Zephyr Piano Enchantment Saffron Carousel Swimming Enchantment Starlight Whimsical Swimming Bamboo Radiance Whisper Piano Whimsical Enchantment Zephyr',8,2.0,4456,'Grace Ellie','Penelope Miles','Javanese');

-- Realistic Books
INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language,image) VALUES('The Great Gatsby', 'A 1925 novel by American writer F. Scott Fitzgerald. Set in the Jazz Age on Long Island, the novel depicts narrator Nick Carraway''s interactions with mysterious millionaire Jay Gatsby.', 180, 20, 10, 'F. Scott Fitzgerald', 'Charles Scribner''s Sons', 'English', 'the_great_gatsby.png');
INSERT INTO product_category(product_id,category_type) VALUES(501,'non-fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('To Kill a Mockingbird', 'A novel by Harper Lee. It explores the irrationality of adult attitudes toward race and class in the Deep South of the 1930s.', 200, 15, 15, 'Harper Lee', 'J.B. Lippincott & Co.', 'English', 'to_kill_a_mockingbird.png');
INSERT INTO product_category(product_id, category_type) VALUES(502, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('1984', 'A dystopian novel by George Orwell. It is set in a superstate known as Oceania, where the ruling party seeks to control thought and suppress personal freedom.', 220, 10, 20, 'George Orwell', 'Secker & Warburg', 'English', '1984.png');
INSERT INTO product_category(product_id, category_type) VALUES(503, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Pride and Prejudice', 'A romantic novel by Jane Austen. It follows the emotional development of Elizabeth Bennet, who learns the error of making hasty judgments and comes to appreciate the difference between the superficial and the essential.', 180, 25, 18, 'Jane Austen', 'T. Egerton, Whitehall', 'English', 'pride_and_prejudice.png');
INSERT INTO product_category(product_id, category_type) VALUES(504, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Hobbit', 'A fantasy novel by J.R.R. Tolkien. It follows the journey of Bilbo Baggins as he sets out on a quest to reclaim a treasure guarded by a dragon.', 250, 18, 12, 'J.R.R. Tolkien', 'George Allen & Unwin', 'English', 'the_hobbit.png');
INSERT INTO product_category(product_id, category_type) VALUES(505, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Catcher in the Rye', 'A novel by J.D. Salinger. It is known for its themes of teenage angst and alienation. The protagonist, Holden Caulfield, experiences a series of events in New York City.', 190, 20, 15, 'J.D. Salinger', 'Little, Brown and Company', 'English', 'the_catcher_in_the_rye.png');
INSERT INTO product_category(product_id, category_type) VALUES(506, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Da Vinci Code', 'A mystery thriller novel by Dan Brown. It follows symbologist Robert Langdon as he investigates a murder at the Louvre Museum in Paris.', 210, 12, 17, 'Dan Brown', 'Doubleday', 'English', 'the_da_vinci_code.png');
INSERT INTO product_category(product_id, category_type) VALUES(507, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Shining', 'A horror novel by Stephen King. It tells the story of Jack Torrance, an aspiring writer and recovering alcoholic who accepts a position as the off-season caretaker of the historic Overlook Hotel in the Colorado Rockies.', 230, 15, 14, 'Stephen King', 'Doubleday', 'English', 'the_shining.png');
INSERT INTO product_category(product_id, category_type) VALUES(508, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Hunger Games', 'A dystopian novel by Suzanne Collins. It is set in the dystopian nation of Panem, where each year, children from the 12 districts are selected to participate in a televised battle to the death.', 240, 18, 16, 'Suzanne Collins', 'Scholastic Corporation', 'English', 'the_hunger_games.png');
INSERT INTO product_category(product_id, category_type) VALUES(509, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Girl on the Train', 'A psychological thriller novel by Paula Hawkins. It follows an alcoholic woman who becomes involved in a missing person investigation.', 200, 20, 13, 'Paula Hawkins', 'Riverhead Books', 'English', 'the_girl_on_the_train.png');
INSERT INTO product_category(product_id, category_type) VALUES(510, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Lord of the Rings', 'A high fantasy novel by J.R.R. Tolkien. The story follows the hobbit Frodo Baggins as he sets out on a quest to destroy the One Ring and defeat the Dark Lord Sauron.', 260, 15, 10, 'J.R.R. Tolkien', 'George Allen & Unwin', 'English', 'the_lord_of_the_rings.png');
INSERT INTO product_category(product_id, category_type) VALUES(511, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Gone Girl', 'A psychological thriller novel by Gillian Flynn. It explores the disintegration of a marriage following the disappearance of a woman on her fifth wedding anniversary.', 210, 18, 15, 'Gillian Flynn', 'Crown Publishing Group', 'English', 'gone_girl.png');
INSERT INTO product_category(product_id, category_type) VALUES(512, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Great Expectations', 'A novel by Charles Dickens. It follows the life of an orphan named Pip, from his childhood through often painful experiences to adulthood.', 190, 22, 12, 'Charles Dickens', 'Chapman & Hall', 'English', 'great_expectations.png');
INSERT INTO product_category(product_id, category_type) VALUES(513, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Harry Potter and the Sorcerer''s Stone', 'A fantasy novel by J.K. Rowling. It follows the journey of a young wizard, Harry Potter, as he discovers his magical abilities and attends Hogwarts School of Witchcraft and Wizardry.', 250, 20, 14, 'J.K. Rowling', 'Bloomsbury', 'English', 'harry_potter_and_the_sorcerers_stone.png');
INSERT INTO product_category(product_id, category_type) VALUES(514, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Fault in Our Stars', 'A novel by John Green. It tells the story of two teenagers, Hazel Grace Lancaster and Augustus Waters, who are dealing with the challenges of living with cancer.', 200, 15, 20, 'John Green', 'Dutton Books', 'English', 'the_fault_in_our_stars.png');
INSERT INTO product_category(product_id, category_type) VALUES(515, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Maze Runner', 'A dystopian science fiction novel by James Dashner. It follows a group of young people who wake up in a mysterious maze with no memory of how they got there.', 220, 18, 18, 'James Dashner', 'Delacorte Press', 'English', 'the_maze_runner.png');
INSERT INTO product_category(product_id, category_type) VALUES(516, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Kite Runner', 'A novel by Khaled Hosseini. It tells the story of Amir, a young boy from Kabul, and his complex relationship with his friend Hassan.', 210, 20, 16, 'Khaled Hosseini', 'Riverhead Books', 'English', 'the_kite_runner.png');
INSERT INTO product_category(product_id, category_type) VALUES(517, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Girl with the Dragon Tattoo', 'A psychological thriller novel by Stieg Larsson. It follows journalist Mikael Blomkvist and hacker Lisbeth Salander as they investigate a wealthy family with dark secrets.', 230, 15, 14, 'Stieg Larsson', 'Norstedts Förlag', 'Swedish', 'the_girl_with_the_dragon_tattoo.png');
INSERT INTO product_category(product_id, category_type) VALUES(518, 'mystery');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Chronicles of Narnia', 'A series of seven fantasy novels by C.S. Lewis. The books follow the adventures of children who are magically transported to the world of Narnia.', 260, 20, 12, 'C.S. Lewis', 'Geoffrey Bles', 'English', 'the_chronicles_of_narnia.png');
INSERT INTO product_category(product_id, category_type) VALUES(519, 'fantasy');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Road', 'A post-apocalyptic novel by Cormac McCarthy. It follows a father and son as they journey across a landscape devastated by an unspecified cataclysm.', 240, 18, 15, 'Cormac McCarthy', 'Alfred A. Knopf', 'English', 'the_road.png');
INSERT INTO product_category(product_id, category_type) VALUES(520, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Alchemist', 'A philosophical novel by Paulo Coelho. It follows the journey of Santiago, a young shepherd, as he sets out to discover his personal legend.', 190, 25, 17, 'Paulo Coelho', 'Rocco', 'Portuguese', 'the_alchemist.png');
INSERT INTO product_category(product_id, category_type) VALUES(521, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Dracula', 'A gothic horror novel by Bram Stoker. It tells the story of Dracula''s attempt to move from Transylvania to England to spread the undead curse, and his battle with a young lawyer named Jonathan Harker.', 220, 15, 20, 'Bram Stoker', 'Archibald Constable & Company', 'English', 'dracula.png');
INSERT INTO product_category(product_id, category_type) VALUES(522, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Outsiders', 'A coming-of-age novel by S.E. Hinton. It follows the lives of two rival groups, the Greasers and the Socs, and the conflicts they face.', 200, 20, 16, 'S.E. Hinton', 'Viking Press', 'English', 'the_outsiders.png');
INSERT INTO product_category(product_id, category_type) VALUES(523, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Stand', 'A post-apocalyptic horror novel by Stephen King. It explores the clash between forces of good and evil in a world ravaged by a deadly pandemic.', 250, 18, 14, 'Stephen King', 'Doubleday', 'English', 'the_stand.png');
INSERT INTO product_category(product_id, category_type) VALUES(524, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Picture of Dorian Gray', 'A philosophical novel by Oscar Wilde. It tells the story of a man whose portrait ages while he remains young and indulges in a hedonistic lifestyle.', 210, 22, 15, 'Oscar Wilde', 'Lippincott''s Monthly Magazine', 'English', 'the_picture_of_dorian_gray.png');
INSERT INTO product_category(product_id, category_type) VALUES(525, 'classic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Grapes of Wrath', 'A novel by John Steinbeck. It follows the Joad family as they travel westward during the Dust Bowl era of the 1930s.', 190, 20, 18, 'John Steinbeck', 'The Viking Press', 'English', 'the_grapes_of_wrath.png');
INSERT INTO product_category(product_id, category_type) VALUES(526, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Frankenstein', 'A gothic novel by Mary Shelley. It tells the story of Victor Frankenstein, a young scientist who creates a sapient creature in an unorthodox scientific experiment.', 220, 15, 20, 'Mary Shelley', 'Lackington, Hughes, Harding, Mavor, & Jones', 'English', 'frankenstein.png');
INSERT INTO product_category(product_id, category_type) VALUES(527, 'horror');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Scarlet Letter', 'A novel by Nathaniel Hawthorne. It explores the consequences of sin and the nature of identity in the 17th-century Puritan society of Massachusetts.', 200, 18, 15, 'Nathaniel Hawthorne', 'Ticknor, Reed, and Fields', 'English', 'the_scarlet_letter.png');
INSERT INTO product_category(product_id, category_type) VALUES(528, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('One Hundred Years of Solitude', 'A novel by Gabriel Garcia Marquez. It tells the multi-generational story of the Buendía family in the fictional town of Macondo.', 240, 25, 14, 'Gabriel Garcia Marquez', 'Editorial Sudamericana', 'Spanish', 'one_hundred_years_of_solitude.png');
INSERT INTO product_category(product_id, category_type) VALUES(529, 'fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Count of Monte Cristo', 'An adventure novel by Alexandre Dumas. It follows the story of Edmond Dantès, a sailor who is falsely accused of treason and seeks revenge against those who betrayed him.', 260, 20, 12, 'Alexandre Dumas', 'Le Journal des Débats', 'French', 'the_count_of_monte_cristo.png');
INSERT INTO product_category(product_id, category_type) VALUES(530, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Catch-22', 'A satirical novel by Joseph Heller. It follows the experiences of a U.S. Army Air Force B-25 bombardier during World War II.', 210, 18, 16, 'Joseph Heller', 'Simon & Schuster', 'English', 'catch_22.png');
INSERT INTO product_category(product_id, category_type) VALUES(531, 'satire');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Handmaid''s Tale', 'A dystopian novel by Margaret Atwood. It is set in the near future where a totalitarian regime has taken control and subjugated women.', 230, 15, 15, 'Margaret Atwood', 'McClelland & Stewart', 'English', 'the_handmaids_tale.png');
INSERT INTO product_category(product_id, category_type) VALUES(532, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Color Purple', 'A novel by Alice Walker. It tells the story of Celie, an African American woman, and her struggles in the early 20th century.', 190, 22, 18, 'Alice Walker', 'Harcourt Brace Jovanovich', 'English', 'the_color_purple.png');
INSERT INTO product_category(product_id, category_type) VALUES(533, 'drama');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Moby-Dick', 'A novel by Herman Melville. It follows the obsessive quest of Ahab, the captain of the whaling ship Pequod, for revenge against the giant white sperm whale, Moby Dick.', 250, 20, 14, 'Herman Melville', 'Richard Bentley', 'English', 'moby_dick.png');
INSERT INTO product_category(product_id, category_type) VALUES(534, 'adventure');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Book Thief', 'A novel by Markus Zusak. It is narrated by Death and tells the story of a young girl named Liesel Meminger in Nazi Germany.', 200, 18, 16, 'Markus Zusak', 'Knopf', 'English', 'the_book_thief.png');
INSERT INTO product_category(product_id, category_type) VALUES(535, 'historical fiction');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Wuthering Heights', 'A novel by Emily Brontë. It explores the destructive effects of passion and revenge in the lives of two Yorkshire families.', 220, 15, 20, 'Emily Brontë', 'Thomas Cautley Newby', 'English', 'wuthering_heights.png');
INSERT INTO product_category(product_id, category_type) VALUES(536, 'romance');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Odyssey', 'An epic poem attributed to Homer. It tells the story of Odysseus and his long journey home after the fall of Troy.', 240, 25, 14, 'Homer', 'Various', 'Ancient Greek', 'the_odyssey.png');
INSERT INTO product_category(product_id, category_type) VALUES(537, 'epic');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Road Less Traveled', 'A self-help book by M. Scott Peck. It explores the importance of discipline and personal growth for a fulfilling life.', 180, 20, 18, 'M. Scott Peck', 'Simon & Schuster', 'English', 'the_road_less_traveled.png');
INSERT INTO product_category(product_id, category_type) VALUES(538, 'self-help');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('Brave New World', 'A dystopian novel by Aldous Huxley. It is set in a futuristic World State where citizens are conditioned for contentment and obedience.', 260, 18, 15, 'Aldous Huxley', 'Chatto & Windus', 'English', 'brave_new_world.png');
INSERT INTO product_category(product_id, category_type) VALUES(539, 'dystopian');
INSERT INTO product(name, synopsis, price, discount, stock, author, editor, language, image) VALUES('The Secret Garden', 'A novel by Frances Hodgson Burnett. It tells the story of Mary Lennox, a lonely and spoiled girl who discovers a hidden, magical garden.', 190, 15, 20, 'Frances Hodgson Burnett', 'Frederick A. Stokes', 'English', 'the_secret_garden.png');
INSERT INTO product_category(product_id, category_type) VALUES(540, 'children''s literature');

INSERT INTO shopping_cart(user_id, product_id) VALUES(89,341);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,163);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,440);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(89,12,3,'paypal','Guarda, Covilh�, Pra�a da Rep�blica, 5123-299','delivered','FALSE','2021-07-01 19:27:54+04','2021-07-09 22:32:39+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,253);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,51);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(55,8,2,'credit/debit card','Coimbra, Set�bal, Rua da Amendoeira, 2494-225','delivered','FALSE','2011-05-04 15:35:39+00','2011-05-20 21:59:48+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,267);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,245);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,392);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(62,90,3,'paypal','Coimbra, Santo Tirso, Avenida do Atl�ntico, 8953-170','order','TRUE','2003-04-10 12:53:29+09','2003-04-24 20:55:11+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(16,464);
INSERT INTO shopping_cart(user_id, product_id) VALUES(16,143);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(16,28,2,'store money','Viseu, Tomar, Avenida das Cam�lias, 2699-887','transportation','FALSE','2005-02-28 14:33:44+09','2005-04-03 01:36:30+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,87);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,490);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(74,6,2,'store money','Guarda, Albufeira, Rua das Oliveiras, 618-717','order','FALSE','2014-12-07 15:01:03+010','2014-12-25 01:26:17+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,255);
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,454);
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,272);
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,500);
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,400);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(63,455,5,'credit/debit card','Porto, Tavira, Rua das Amar�lis, 2079-488','payment','FALSE','2002-10-19 11:25:38+00','2002-11-17 18:41:26+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(41,111);
INSERT INTO shopping_cart(user_id, product_id) VALUES(41,25);
INSERT INTO shopping_cart(user_id, product_id) VALUES(41,392);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(41,48,3,'credit/debit card','Guarda, Castelo de Vide, Avenida das Flores, 7291-856','payment','FALSE','2008-09-04 13:03:59+04','2008-09-16 20:14:25+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,370);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,333);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(28,78,2,'store money','Santar�m, Albufeira, Pra�a da Rep�blica, 2593-324','order','FALSE','2011-09-15 00:05:09+05','2011-09-20 09:56:11+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,20);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,394);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,410);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,448);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,433);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(78,295,5,'store money','�vora, Vila do Conde, Rua da Ribeira, 1798-212','order','FALSE','2003-01-10 00:48:17+00','2003-01-16 23:28:26+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,34);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,94);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(89,130,2,'store money','Aveiro, Amadora, Rua dos Mercadores, 3830-503','payment','TRUE','2023-09-27 19:33:06+02','2023-10-14 03:48:55+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,23);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,333);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,87);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,439);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,405);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(34,165,5,'store money','Portalegre, Paredes, Pra�a da S�, 5990-252','order','FALSE','2018-12-19 15:04:21+06','2019-01-11 06:30:38+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,46);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,56);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,315);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,2);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(13,332,4,'store money','Santar�m, Lagos, Rua da Glic�nia, 619-283','payment','FALSE','2019-11-17 04:20:51+010','2019-11-21 11:20:36+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(45,387);
INSERT INTO shopping_cart(user_id, product_id) VALUES(45,112);
INSERT INTO shopping_cart(user_id, product_id) VALUES(45,156);
INSERT INTO shopping_cart(user_id, product_id) VALUES(45,51);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(45,272,4,'paypal','Santar�m, Elvas, Pra�a de Cam�es, 4335-735','delivered','TRUE','2003-10-27 08:55:35+03','2003-11-19 21:23:46+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(30,262);
INSERT INTO shopping_cart(user_id, product_id) VALUES(30,161);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(30,104,2,'store money','Aveiro, Vila Franca de Xira, Rua da Escola, 2948-252','payment','FALSE','2010-04-02 22:28:32+011','2010-04-20 11:25:10+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,34);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,185);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,191);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,186);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,60);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(44,405,5,'paypal','Bragan�a, Ponte de Lima, Rua das T�lipas, 2203-739','transportation','FALSE','2016-06-07 12:55:26+07','2016-07-04 06:43:34+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,179);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,167);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(6,198,2,'store money','Viseu, Albufeira, Rua dos L�rios, 2842-462','order','TRUE','2000-03-21 16:06:44+08','2000-04-08 12:12:08+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,325);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,412);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,186);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(12,300,3,'store money','Leiria, Castelo Branco, Rua dos Cedros, 7236-367','delivered','TRUE','2007-04-26 10:18:40+03','2007-05-30 17:46:30+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,344);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,430);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,261);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,141);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(28,52,4,'credit/debit card','Guarda, Loures, Rua das Margaridas, 4020-885','delivered','FALSE','2009-12-04 10:35:47+07','2010-01-06 08:28:41+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,386);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,186);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(64,126,2,'credit/debit card','Bragan�a, Loul�, Avenida das Violetas, 1417-625','payment','TRUE','2019-07-03 05:28:14+08','2019-07-03 22:09:01+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,30);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,458);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,391);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,240);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(28,76,4,'store money','Coimbra, Matosinhos, Rua das Orqu�deas, 7850-990','payment','TRUE','2007-05-30 21:00:21+03','2007-06-08 22:53:34+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,284);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,52);
INSERT INTO shopping_cart(user_id, product_id) VALUES(44,335);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(44,72,3,'paypal','Coimbra, Covilh�, Rua das Margaridas, 6603-306','order','TRUE','2006-10-08 22:14:49+01','2006-10-17 08:53:48+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(73,232);
INSERT INTO shopping_cart(user_id, product_id) VALUES(73,460);
INSERT INTO shopping_cart(user_id, product_id) VALUES(73,123);
INSERT INTO shopping_cart(user_id, product_id) VALUES(73,329);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(73,304,4,'paypal','Beja, Sesimbra, Rua da Fraternidade, 8633-109','order','TRUE','2015-07-26 21:21:59+08','2015-07-30 02:17:02+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,470);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,111);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,171);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,119);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(9,24,4,'store money','Coimbra, Albufeira, Rua da Amendoeira, 6171-799','delivered','FALSE','2022-05-20 07:14:15+02','2022-06-19 03:33:07+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,251);
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,58);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(50,132,2,'store money','Viseu, Vila Real de Santo Ant�nio, Rua das T�lipas, 8647-902','delivered','FALSE','2001-08-30 05:16:39+03','2001-09-13 01:48:41+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,101);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,450);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,278);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(15,93,3,'paypal','Viseu, Vila Real, Rua da Saudade, 9715-445','payment','TRUE','2011-10-15 19:26:44+05','2011-10-29 04:20:33+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,179);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,11);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,162);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,45);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(49,336,4,'store money','Leiria, Santo Tirso, Pra�a das Beg�nias, 5724-216','payment','TRUE','2009-08-18 09:35:24+00','2009-09-15 16:04:07+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,391);
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,185);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(58,54,2,'paypal','Bragan�a, Loul�, Rua das Rosas, 2168-152','transportation','FALSE','2013-07-01 03:56:23+06','2013-07-28 20:44:15+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,450);
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,309);
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,52);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(99,33,3,'paypal','Santar�m, Maia, Rua da Cidade, 7197-769','order','FALSE','2012-05-07 08:21:58+011','2012-05-28 00:40:14+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,92);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,10);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,220);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,444);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,431);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(6,100,5,'paypal','Coimbra, Gondomar, Rua das Magn�lias, 1457-808','order','TRUE','2008-10-30 16:03:49+00','2008-11-05 03:47:33+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(95,104);
INSERT INTO shopping_cart(user_id, product_id) VALUES(95,332);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(95,126,2,'paypal','�vora, Amarante, Rua da Solid�o, 6261-637','order','TRUE','2004-02-10 10:19:58+011','2004-03-07 14:47:20+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,23);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,266);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,150);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,246);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,419);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(94,465,5,'credit/debit card','Leiria, Beira-Mar, Avenida Marginal, 280-789','order','TRUE','2001-08-14 09:16:54+012','2001-09-14 00:27:15+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,128);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,111);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,366);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,234,3,'credit/debit card','Faro, Matosinhos, Pra�a do Infante, 3868-487','delivered','TRUE','2015-09-21 05:39:11+010','2015-10-17 03:10:10+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,106);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,12);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,324);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(6,231,3,'store money','Santar�m, S�o Jo�o da Madeira, Largo das Oliveiras, 8776-100','order','TRUE','2018-12-30 07:19:35+012','2019-01-11 19:58:09+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,310);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,10);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,99);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,321);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(10,388,4,'credit/debit card','Vila Real, Trofa, Rua da Aldeia, 3478-844','delivered','FALSE','2017-01-19 22:07:05+03','2017-02-04 16:26:46+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,176);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,58);
INSERT INTO shopping_cart(user_id, product_id) VALUES(78,152);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(78,162,3,'store money','Braga, �gueda, Rua dos Pinheiros, 5834-875','transportation','FALSE','2020-05-05 21:21:24+06','2020-05-25 09:01:00+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,305);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,156);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,151);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,210);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,396);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(14,75,5,'credit/debit card','Leiria, Beira-Mar, Avenida da Liberdade, 4100-941','order','TRUE','2008-08-23 01:20:09+03','2008-08-25 18:00:08+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,24);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,114);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,416);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,1);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,71);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(10,490,5,'store money','Santar�m, Santo Tirso, Rua do Ouro, 6769-509','delivered','TRUE','2014-12-05 01:17:42+03','2014-12-26 18:47:44+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,32);
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,383);
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,374);
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,32);
INSERT INTO shopping_cart(user_id, product_id) VALUES(58,492);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(58,330,5,'paypal','Porto, Figueira da Foz, Rua das Beg�nias, 6929-118','transportation','TRUE','2021-06-26 11:00:21+07','2021-07-24 20:41:07+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(23,166);
INSERT INTO shopping_cart(user_id, product_id) VALUES(23,200);
INSERT INTO shopping_cart(user_id, product_id) VALUES(23,23);
INSERT INTO shopping_cart(user_id, product_id) VALUES(23,223);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(23,204,4,'store money','Porto, Odivelas, Pra�a do Com�rcio, 7432-730','order','FALSE','2002-04-12 18:41:46+02','2002-05-14 22:28:00+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,218);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,50);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,263);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(69,207,3,'store money','Viseu, Tomar, Avenida da Paz, 3731-896','delivered','TRUE','2021-12-24 13:52:51+02','2022-01-07 15:34:03+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,94);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,32);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,6);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,115);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,87);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(32,330,5,'paypal','Faro, Vila Franca de Xira, Rua da Amendoeira, 8877-756','order','TRUE','2002-12-29 05:08:57+01','2002-12-29 10:37:50+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(95,168);
INSERT INTO shopping_cart(user_id, product_id) VALUES(95,223);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(95,126,2,'paypal','Faro, Gondomar, Rua do Porto, 607-233','payment','TRUE','2011-12-20 23:36:36+02','2012-01-09 10:08:29+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,141);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,330);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,152,2,'paypal','�vora, S�o Jo�o da Madeira, Rua da Madressilva, 2806-313','payment','TRUE','2017-05-10 03:49:09+05','2017-05-24 14:55:04+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,58);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,1);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(64,152,2,'paypal','Santar�m, Bragan�a, Pra�a da Rep�blica, 6663-190','payment','FALSE','2004-04-30 09:55:36+08','2004-05-01 23:33:28+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,331);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,18);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(28,164,2,'paypal','Santar�m, �gueda, Avenida das Flores, 3725-577','transportation','TRUE','2003-08-23 17:07:48+011','2003-09-01 10:20:52+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,247);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,39);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(82,38,2,'paypal','Braga, Paredes, Avenida das Ac�cias, 784-104','delivered','TRUE','2013-07-29 17:46:20+05','2013-07-30 00:58:18+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,187);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,242);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,436);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(12,252,3,'store money','Viana do Castelo, Loul�, Rua dos Choupos, 9175-655','order','TRUE','2009-01-04 21:30:34+00','2009-01-21 09:00:01+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(56,457);
INSERT INTO shopping_cart(user_id, product_id) VALUES(56,39);
INSERT INTO shopping_cart(user_id, product_id) VALUES(56,412);
INSERT INTO shopping_cart(user_id, product_id) VALUES(56,364);
INSERT INTO shopping_cart(user_id, product_id) VALUES(56,135);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(56,190,5,'paypal','Porto, Bragan�a, Rua dos P�ssaros, 1319-435','payment','FALSE','2006-11-13 13:06:06+011','2006-11-21 17:32:17+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,150);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,495);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,342);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,476);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(21,160,4,'credit/debit card','Coimbra, Chaves, Rua dos P�ssaros, 4577-732','transportation','TRUE','2004-01-12 07:10:20+09','2004-02-07 03:02:18+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,305);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,106);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,155);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,45);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,373);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(76,105,5,'credit/debit card','Porto, Lamego, Pra�a de Cam�es, 8054-408','order','TRUE','2015-11-15 18:38:37+00','2015-12-17 20:39:36+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,192);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,182);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,24);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,309);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,314);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(37,35,5,'paypal','Aveiro, Ponte de Lima, Rua de Santo Ant�nio, 3245-401','delivered','TRUE','2019-07-22 00:56:49+06','2019-08-24 11:39:32+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,278);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,184);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,377);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,468);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,181);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(92,10,5,'store money','Viana do Castelo, Tomar, Pra�a da Alegria, 4384-786','transportation','FALSE','2013-12-14 21:33:59+08','2013-12-25 22:01:38+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,87);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,355);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,480);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,327);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(69,140,4,'paypal','�vora, Vila Nova de Gaia, Avenida das Ac�cias, 8221-948','payment','TRUE','2013-12-17 12:00:43+04','2013-12-31 02:52:10+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(81,412);
INSERT INTO shopping_cart(user_id, product_id) VALUES(81,193);
INSERT INTO shopping_cart(user_id, product_id) VALUES(81,292);
INSERT INTO shopping_cart(user_id, product_id) VALUES(81,496);
INSERT INTO shopping_cart(user_id, product_id) VALUES(81,326);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(81,215,5,'credit/debit card','Castelo Branco, Albufeira, Avenida das Ac�cias, 5761-853','payment','FALSE','2002-11-14 21:12:07+010','2002-12-03 00:32:31+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(52,313);
INSERT INTO shopping_cart(user_id, product_id) VALUES(52,183);
INSERT INTO shopping_cart(user_id, product_id) VALUES(52,79);
INSERT INTO shopping_cart(user_id, product_id) VALUES(52,265);
INSERT INTO shopping_cart(user_id, product_id) VALUES(52,367);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(52,215,5,'credit/debit card','Bragan�a, Lagos, Pra�a dos Jacarand�s, 5120-130','order','FALSE','2015-01-16 23:43:18+03','2015-01-24 00:48:37+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,164);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,21);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,268);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(5,18,3,'credit/debit card','Lisboa, Castelo de Vide, Largo das Palmas, 3265-584','order','TRUE','2023-09-12 09:19:48+02','2023-09-26 10:28:46+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,201);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,432);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,148);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,61);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,116);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(76,220,5,'credit/debit card','Aveiro, Vila Real de Santo Ant�nio, Rua de Santa Catarina, 2927-596','order','FALSE','2007-12-28 05:04:59+06','2008-01-29 03:56:48+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,326);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,121);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,143);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(19,99,3,'store money','Santar�m, Estoril, Rua da Fonte, 4336-476','order','FALSE','2014-08-21 09:17:39+02','2014-09-08 14:35:03+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,383);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,439);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,160);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,1);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,455);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(31,280,5,'paypal','Guarda, Valongo, Rua dos Cravos, 6447-467','payment','FALSE','2015-12-08 08:38:30+09','2015-12-15 07:07:41+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,316);
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,58);
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,342);
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,492);
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,463);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(84,95,5,'store money','Viseu, Vila Real de Santo Ant�nio, Rua do Po�o, 7228-747','delivered','FALSE','2008-10-11 08:29:08+02','2008-11-12 13:43:22+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,139);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,482);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,398);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,297);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,379);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(9,495,5,'credit/debit card','�vora, Odivelas, Rua das Orqu�deas, 1343-739','transportation','FALSE','2023-11-26 15:18:57+07','2023-12-24 03:26:27+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,291);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,388);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,19);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(74,18,3,'credit/debit card','Bragan�a, Castelo de Vide, Rua da Alfazema, 4178-207','order','FALSE','2003-08-16 23:51:02+03','2003-08-17 21:53:27+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,482);
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,441);
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,370);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(77,144,3,'credit/debit card','Viseu, Valongo, Avenida da Democracia, 9980-579','transportation','FALSE','2019-01-16 21:16:38+011','2019-01-17 19:38:55+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,117);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,14);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,21);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(33,180,3,'credit/debit card','Faro, Odivelas, Avenida da Felicidade, 1328-116','delivered','FALSE','2016-07-22 08:42:38+01','2016-08-17 00:18:18+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,370);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,317);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,334);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,489);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(59,112,4,'store money','Leiria, P�voa de Varzim, Rua da Tranquilidade, 4379-829','delivered','FALSE','2017-09-27 00:56:03+05','2017-09-30 19:05:11+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,129);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,232);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,17);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,268);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,399);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(76,400,5,'credit/debit card','Set�bal, Sesimbra, Rua dos Choupos, 8129-828','order','TRUE','2004-05-04 04:01:32+012','2004-05-18 06:48:18+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,59);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,14);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,357);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(8,99,3,'paypal','Faro, Tomar, Avenida das Flores, 7411-382','payment','FALSE','2016-03-29 11:24:51+07','2016-05-01 22:09:42+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,151);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,265);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(94,68,2,'paypal','Portalegre, Chaves, Rua da Liberdade, 9234-351','payment','FALSE','2006-09-18 09:00:11+09','2006-10-08 04:10:50+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,408);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,4);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,494);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,453);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,47);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(5,465,5,'credit/debit card','Porto, Elvas, Rua dos Lilases, 8761-775','payment','TRUE','2001-03-04 15:42:07+012','2001-03-21 08:29:00+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,132);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,188);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,6);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,168,3,'store money','Santar�m, Almada, Largo da Fonte, 406-681','order','FALSE','2004-05-24 11:36:38+00','2004-06-07 02:08:53+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,410);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,247);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,274);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,88);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,419);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(60,110,5,'store money','Lisboa, S�o Jo�o da Madeira, Rua de S�o Jo�o, 5497-774','payment','TRUE','2012-04-21 04:36:15+00','2012-05-07 23:52:42+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,168);
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,149);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(24,116,2,'store money','Portalegre, Trofa, Largo do Mercado, 2499-785','payment','TRUE','2023-01-10 16:33:37+01','2023-01-19 07:03:30+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,95);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,421);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,105);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,383);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,330);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(33,315,5,'paypal','Vila Real, Penafiel, Rua da Tecnologia, 7200-270','transportation','FALSE','2013-07-22 04:08:55+012','2013-07-24 14:31:20+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,474);
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,77);
INSERT INTO shopping_cart(user_id, product_id) VALUES(77,408);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(77,69,3,'paypal','Portalegre, Paredes, Pra�a do Com�rcio, 2124-698','transportation','FALSE','2008-12-12 01:41:06+01','2008-12-18 10:11:03+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,112);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,345);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(82,122,2,'credit/debit card','Braga, Vila Nova de Gaia, Avenida da Paz, 8263-725','delivered','FALSE','2001-08-18 07:57:01+011','2001-09-07 05:36:32+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,183);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,204);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,318);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,28);
INSERT INTO shopping_cart(user_id, product_id) VALUES(82,16);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(82,445,5,'credit/debit card','Coimbra, Odivelas, Pra�a do Com�rcio, 5592-404','order','FALSE','2017-10-11 04:19:31+011','2017-11-04 05:46:57+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,125);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,435);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,354);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(13,150,3,'paypal','Set�bal, Tavira, Largo do Mercado, 2052-524','delivered','FALSE','2023-04-27 09:29:58+00','2023-04-28 12:07:46+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,272);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,230);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,131);
INSERT INTO shopping_cart(user_id, product_id) VALUES(94,379);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(94,336,4,'credit/debit card','Lisboa, Caldas da Rainha, Rua da Alameda, 6715-773','order','TRUE','2023-07-19 13:50:14+07','2023-08-20 07:06:39+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,54);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,494);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(15,52,2,'store money','Castelo Branco, Sesimbra, Rua da Inova��o, 7506-874','payment','FALSE','2019-09-21 08:41:34+04','2019-10-16 11:06:19+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,280);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,425);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,290);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,104);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(14,52,4,'store money','Viana do Castelo, Beira-Mar, Pra�a da Diversidade, 6619-635','order','FALSE','2006-12-18 00:27:18+06','2006-12-23 18:30:28+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,247);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,481);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,167);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,451);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(21,148,4,'credit/debit card','Vila Real, Lagos, Pra�a do Rossio, 3657-123','transportation','TRUE','2010-08-16 14:36:04+03','2010-09-14 07:57:13+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,216);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,345);
INSERT INTO shopping_cart(user_id, product_id) VALUES(14,243);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(14,144,3,'credit/debit card','Viseu, Santo Tirso, Avenida dos Descobrimentos, 8252-826','payment','FALSE','2005-06-07 10:25:15+09','2005-06-24 23:09:46+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,13);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,23);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,75);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(55,51,3,'store money','Porto, S�o Jo�o da Madeira, Rua das Hort�nsias, 45-206','order','FALSE','2011-11-11 09:04:45+03','2011-11-30 14:53:03+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,85);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,445);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,261);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(12,207,3,'store money','Coimbra, Sesimbra, Avenida das Cam�lias, 70-938','payment','FALSE','2001-01-25 21:27:31+06','2001-01-26 09:09:42+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,325);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,363);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,85);
INSERT INTO shopping_cart(user_id, product_id) VALUES(37,249);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(37,188,4,'store money','Faro, Beira-Mar, Rua dos Choupos, 878-966','transportation','TRUE','2021-03-11 21:38:29+012','2021-03-17 22:58:25+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,306);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,420);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,405);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,305);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,333);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,325,5,'store money','Viana do Castelo, Esposende, Rua do Carmo, 7082-902','order','TRUE','2013-01-20 18:09:22+02','2013-02-18 08:15:14+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,163);
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,458);
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,147);
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,21);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(80,96,4,'store money','Vila Real, Barreiro, Pra�a das Beg�nias, 1577-873','order','TRUE','2016-09-02 22:18:33+011','2016-09-17 18:01:12+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,443);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,86);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,21);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(9,204,3,'paypal','Coimbra, Oeiras, Rua da Inova��o, 690-585','payment','TRUE','2021-11-09 12:45:29+00','2021-11-22 14:42:41+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,220);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,102);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(5,18,2,'paypal','Vila Real, Loul�, Rua dos P�ssaros, 2015-924','delivered','TRUE','2015-10-23 01:42:51+06','2015-11-21 08:56:35+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,260);
INSERT INTO shopping_cart(user_id, product_id) VALUES(13,242);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(13,82,2,'paypal','Guarda, Lagos, Avenida das Orqu�deas, 2424-792','delivered','FALSE','2007-03-17 16:43:03+03','2007-03-21 04:11:49+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,70);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,319);
INSERT INTO shopping_cart(user_id, product_id) VALUES(32,207);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(32,90,3,'store money','Set�bal, S�o Jo�o da Madeira, Avenida Marginal, 4915-648','order','TRUE','2000-03-09 01:26:56+08','2000-03-13 00:54:27+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,258);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,107);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,341);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,9);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,462);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(12,190,5,'paypal','�vora, Figueira da Foz, Avenida das Orqu�deas, 1436-487','payment','TRUE','2001-05-05 01:47:27+06','2001-05-08 17:11:38+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,53);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,419);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,124,2,'credit/debit card','Viseu, Paredes, Avenida dos Jacarand�s, 4188-650','payment','FALSE','2018-07-20 00:19:32+012','2018-08-02 18:53:35+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(46,7);
INSERT INTO shopping_cart(user_id, product_id) VALUES(46,246);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(46,170,2,'paypal','Leiria, Figueira da Foz, Rua das Orqu�deas, 4126-262','payment','TRUE','2000-12-02 12:29:25+01','2000-12-09 22:24:07+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,57);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,239);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,410);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,288,3,'credit/debit card','Bragan�a, Almada, Largo das Az�leas, 7865-357','delivered','FALSE','2013-10-12 11:14:15+011','2013-10-25 00:28:58+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,62);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,225);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(74,46,2,'store money','Viana do Castelo, Barreiro, Travessa das Flores, 5465-309','transportation','FALSE','2008-09-26 05:04:42+04','2008-09-27 05:26:01+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,413);
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,257);
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,356);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(85,192,3,'credit/debit card','Viseu, Vila Nova de Gaia, Rua das Estrelas, 3360-272','payment','FALSE','2013-02-09 06:58:04+08','2013-02-26 14:21:08+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,264);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,26);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,49);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,187);
INSERT INTO shopping_cart(user_id, product_id) VALUES(34,369);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(34,480,5,'paypal','Porto, Ponte de Lima, Rua da Montanha, 7824-264','delivered','TRUE','2023-08-27 01:46:09+04','2023-09-28 09:01:12+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,362);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,123);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(10,60,2,'credit/debit card','Santar�m, Tavira, Avenida da Marina, 1370-518','payment','FALSE','2009-09-16 01:27:14+08','2009-10-08 09:05:21+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,174);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,354);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,155);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,383);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,70);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,495,5,'credit/debit card','Aveiro, Castelo Branco, Rua do Bem-estar, 8629-412','transportation','TRUE','2011-10-20 00:47:58+04','2011-10-31 23:52:16+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,31);
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,494);
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,464);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(22,90,3,'store money','Guarda, Tavira, Rua de S�o Jo�o, 7859-294','transportation','FALSE','2017-05-03 13:46:38+00','2017-05-18 14:34:06+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,422);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,158);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,186);
INSERT INTO shopping_cart(user_id, product_id) VALUES(5,396);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(5,60,4,'paypal','Set�bal, Paredes, Rua do Vale, 2507-830','payment','TRUE','2008-10-29 09:25:34+011','2008-11-18 23:56:52+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(70,4);
INSERT INTO shopping_cart(user_id, product_id) VALUES(70,400);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(70,192,2,'paypal','Leiria, Lamego, Largo das Palmas, 6529-538','transportation','TRUE','2009-04-08 01:55:33+07','2009-04-19 12:58:55+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,164);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,462);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,385);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(21,201,3,'credit/debit card','Lisboa, Santo Tirso, Avenida dos Ciprestes, 5222-701','order','TRUE','2018-03-26 14:06:46+00','2018-04-18 01:31:02+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,68);
INSERT INTO shopping_cart(user_id, product_id) VALUES(84,439);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(84,52,2,'store money','Lisboa, Amarante, Avenida das Ac�cias, 5878-375','order','FALSE','2003-03-21 15:24:56+03','2003-04-17 05:35:44+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(67,460);
INSERT INTO shopping_cart(user_id, product_id) VALUES(67,138);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(67,6,2,'credit/debit card','Guarda, Sesimbra, Rua da Alegria, 272-672','order','TRUE','2020-09-25 03:49:51+010','2020-10-22 04:17:19+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,404);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,116);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,428);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,104);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,2);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(7,255,5,'credit/debit card','Aveiro, S�o Jo�o da Madeira, Rua das Artes, 2397-513','delivered','FALSE','2022-04-19 07:56:18+00','2022-05-09 17:07:32+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,85);
INSERT INTO shopping_cart(user_id, product_id) VALUES(33,387);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(33,52,2,'store money','Castelo Branco, Chaves, Rua das Rosas, 5632-994','payment','TRUE','2022-05-24 22:52:33+08','2022-06-06 13:26:57+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,73);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,70);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,354);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,10);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(92,120,4,'credit/debit card','Lisboa, Esmoriz, Largo da S�, 4313-453','transportation','FALSE','2015-04-07 03:12:27+06','2015-04-17 11:00:14+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,4);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,384);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,276);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(26,141,3,'credit/debit card','Aveiro, Set�bal, Rua da Cova, 5087-640','order','TRUE','2017-12-24 11:50:50+010','2018-01-10 14:01:58+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,273);
INSERT INTO shopping_cart(user_id, product_id) VALUES(63,456);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(63,116,2,'store money','Santar�m, Paredes, Rua das Glic�nias, 5339-840','order','FALSE','2016-08-22 02:52:23+00','2016-09-09 16:12:23+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,225);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,398);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,60);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,231);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,54);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(96,215,5,'paypal','Leiria, Santa Maria da Feira, Rua da Alameda, 2102-882','order','TRUE','2010-12-16 03:03:28+010','2011-01-02 02:35:05+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(66,450);
INSERT INTO shopping_cart(user_id, product_id) VALUES(66,347);
INSERT INTO shopping_cart(user_id, product_id) VALUES(66,193);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(66,51,3,'credit/debit card','Leiria, Sesimbra, Largo do Chafariz, 3922-185','delivered','TRUE','2015-02-27 07:36:45+07','2015-03-20 16:42:43+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,354);
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,51);
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,334);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(87,15,3,'store money','Leiria, S�o Jo�o da Madeira, Rua dos Cravos, 1285-787','payment','TRUE','2007-07-25 12:08:18+04','2007-08-07 14:07:07+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,220);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,444);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,397);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,395);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,136);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(92,145,5,'credit/debit card','Viana do Castelo, Matosinhos, Rua da Inova��o, 1363-472','transportation','TRUE','2009-01-08 17:32:25+07','2009-01-24 21:45:03+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,166);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,450);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,348);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,266);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(15,120,4,'store money','Lisboa, Chaves, Avenida dos Descobrimentos, 3994-904','payment','FALSE','2010-09-26 02:11:18+03','2010-10-21 07:24:54+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,220);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,213);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,482);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,364);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,175);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,155,5,'paypal','Santar�m, S�o Jo�o da Madeira, Rua do Cabo, 5277-623','delivered','TRUE','2009-05-29 10:49:56+05','2009-06-18 13:15:46+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(61,473);
INSERT INTO shopping_cart(user_id, product_id) VALUES(61,53);
INSERT INTO shopping_cart(user_id, product_id) VALUES(61,228);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(61,99,3,'paypal','Portalegre, Lamego, Rua das Margaridas, 9356-623','payment','TRUE','2020-02-21 03:46:00+05','2020-02-26 11:26:19+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,61);
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,467);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(65,112,2,'credit/debit card','Viseu, Barreiro, Rua das Hort�nsias, 7783-238','transportation','TRUE','2018-06-14 18:42:13+07','2018-06-27 02:20:33+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,394);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,195);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,229);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,227);
INSERT INTO shopping_cart(user_id, product_id) VALUES(31,249);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(31,185,5,'paypal','Beja, Tavira, Rua dos P�ssaros, 3263-105','payment','TRUE','2017-03-28 05:01:57+010','2017-04-21 22:23:49+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,429);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,288);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(17,58,2,'credit/debit card','Lisboa, Santo Tirso, Rua das Estrelas, 6975-273','order','FALSE','2016-08-09 10:54:13+01','2016-08-25 08:37:17+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,130);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,267);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,247);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,420);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(19,48,4,'credit/debit card','Vila Real, Figueira da Foz, Rua da Alameda, 306-465','transportation','TRUE','2007-10-27 04:53:29+00','2007-11-25 15:41:18+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,105);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,302);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(49,122,2,'store money','Bragan�a, Tomar, Rua dos Choupos, 2084-277','order','TRUE','2010-05-21 00:43:15+03','2010-05-28 10:13:40+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,357);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,481);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,24);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(98,216,3,'credit/debit card','Viseu, Amadora, Rua da Esperan�a, 4019-157','payment','TRUE','2003-07-22 15:14:30+04','2003-07-24 03:44:35+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,62);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,243);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,488);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(64,9,3,'paypal','Leiria, Gondomar, Rua do Castelo, 9751-461','payment','FALSE','2000-07-31 19:31:07+01','2000-08-24 16:48:40+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,431);
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,157);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(71,188,2,'credit/debit card','Coimbra, Gondomar, Largo da Fonte, 1707-927','transportation','FALSE','2020-10-16 06:30:36+08','2020-10-18 03:26:47+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(30,445);
INSERT INTO shopping_cart(user_id, product_id) VALUES(30,164);
INSERT INTO shopping_cart(user_id, product_id) VALUES(30,99);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(30,180,3,'paypal','Porto, Amadora, Avenida Dom Jo�o II, 7553-284','delivered','FALSE','2011-10-19 08:11:33+05','2011-11-11 13:53:13+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,14);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,491);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,447);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,162);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(19,180,4,'credit/debit card','Beja, Maia, Rua da Solidariedade, 6215-429','order','FALSE','2002-07-30 17:22:13+09','2002-09-01 05:10:16+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,474);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,140);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,260);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,385);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(19,228,4,'credit/debit card','Beja, �gueda, Rua dos Anjos, 4257-967','order','TRUE','2021-07-17 06:46:34+010','2021-08-14 07:16:12+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,30);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,370);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,274);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(59,276,3,'credit/debit card','Porto, Vila Real, Rua das �rvores, 9471-864','payment','FALSE','2008-01-19 15:05:55+012','2008-02-11 18:04:50+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,143);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,222);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,299);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,215);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,126);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,275,5,'store money','Viana do Castelo, Rio Maior, Rua dos Direitos Humanos, 8138-825','transportation','TRUE','2023-05-17 13:48:51+08','2023-05-26 01:05:44+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,417);
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,73);
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,83);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(93,222,3,'paypal','Set�bal, Fafe, Largo da Fonte, 7476-430','payment','FALSE','2023-10-29 06:17:11+04','2023-11-18 09:49:07+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,479);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,12);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,190);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,39);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,153);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(90,335,5,'credit/debit card','Viana do Castelo, Castelo Branco, Largo da S�, 4927-502','delivered','TRUE','2017-01-20 20:33:40+02','2017-02-05 09:39:40+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(48,15);
INSERT INTO shopping_cart(user_id, product_id) VALUES(48,99);
INSERT INTO shopping_cart(user_id, product_id) VALUES(48,434);
INSERT INTO shopping_cart(user_id, product_id) VALUES(48,131);
INSERT INTO shopping_cart(user_id, product_id) VALUES(48,32);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(48,375,5,'credit/debit card','Coimbra, Vila Franca de Xira, Rua do Porto, 6500-844','payment','FALSE','2009-12-01 17:47:34+03','2009-12-30 13:10:29+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,379);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,471);
INSERT INTO shopping_cart(user_id, product_id) VALUES(49,47);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(49,276,3,'credit/debit card','Bragan�a, Castelo Branco, Rua do Cabo, 5982-648','order','FALSE','2006-04-27 19:55:11+09','2006-05-25 00:12:48+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(46,408);
INSERT INTO shopping_cart(user_id, product_id) VALUES(46,204);
INSERT INTO shopping_cart(user_id, product_id) VALUES(46,18);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(46,156,3,'store money','Vila Real, Fafe, Rua de Santo Ant�nio, 6543-851','delivered','TRUE','2001-06-20 06:20:36+04','2001-07-23 10:44:46+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,410);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,24);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,497);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,219);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,197);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(96,10,5,'paypal','Viseu, Lamego, Pra�a dos Her�is, 5995-875','transportation','TRUE','2007-06-27 14:19:34+05','2007-07-01 05:36:58+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,142);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,453);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(98,36,2,'credit/debit card','Lisboa, Albufeira, Rua do Carmo, 8910-655','order','TRUE','2018-07-24 02:48:06+011','2018-08-25 05:57:52+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(25,366);
INSERT INTO shopping_cart(user_id, product_id) VALUES(25,333);
INSERT INTO shopping_cart(user_id, product_id) VALUES(25,50);
INSERT INTO shopping_cart(user_id, product_id) VALUES(25,371);
INSERT INTO shopping_cart(user_id, product_id) VALUES(25,496);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(25,285,5,'paypal','Aveiro, Vila Real de Santo Ant�nio, Rua dos Cris�ntemos, 5124-831','delivered','FALSE','2004-06-09 22:34:50+06','2004-06-22 19:02:13+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,43);
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,351);
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,145);
INSERT INTO shopping_cart(user_id, product_id) VALUES(87,102);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(87,164,4,'credit/debit card','Faro, Rio Maior, Rua da Uni�o, 1905-737','delivered','TRUE','2009-09-17 11:17:32+012','2009-10-11 15:26:34+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,118);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,116);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(15,22,2,'credit/debit card','Viseu, S�o Jo�o da Madeira, Rua da Quinta, 5275-675','order','FALSE','2005-01-13 18:37:29+02','2005-01-16 21:14:42+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,117);
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,164);
INSERT INTO shopping_cart(user_id, product_id) VALUES(22,188);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(22,219,3,'paypal','�vora, Amarante, Rua da Glic�nia, 7368-532','delivered','FALSE','2005-05-24 19:55:59+04','2005-06-25 00:20:59+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,406);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,369);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,364);
INSERT INTO shopping_cart(user_id, product_id) VALUES(59,129);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(59,180,4,'paypal','Portalegre, Amarante, Pra�a dos Jacarand�s, 93-415','payment','FALSE','2023-09-19 22:56:22+09','2023-09-24 09:57:12+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(16,7);
INSERT INTO shopping_cart(user_id, product_id) VALUES(16,314);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(16,132,2,'paypal','Lisboa, Tomar, Pra�a do Com�rcio, 3969-248','transportation','FALSE','2014-11-01 20:44:33+00','2014-11-18 03:13:51+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(38,284);
INSERT INTO shopping_cart(user_id, product_id) VALUES(38,376);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(38,150,2,'store money','Beja, Estoril, Rua da Igualdade, 721-976','payment','FALSE','2000-10-15 16:28:38+08','2000-10-18 03:17:36+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,9);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,254);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,291);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,129);
INSERT INTO shopping_cart(user_id, product_id) VALUES(64,390);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(64,325,5,'credit/debit card','Viseu, Maia, Rua da Esperan�a, 9060-280','order','TRUE','2004-10-17 02:04:14+011','2004-11-05 21:48:37+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,132);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,245);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,90,2,'store money','Coimbra, �gueda, Rua dos Pinheiros, 5870-661','delivered','FALSE','2007-05-24 14:40:50+03','2007-06-06 07:06:41+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,291);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,441);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,82);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(92,252,3,'paypal','Braga, Esposende, Pra�a da Cultura, 6538-564','order','TRUE','2006-12-06 11:24:40+08','2006-12-29 04:19:40+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,260);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,14);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(62,32,2,'credit/debit card','Viana do Castelo, Penafiel, Rua do Porto, 3107-405','payment','FALSE','2014-06-15 12:42:11+05','2014-06-29 03:31:06+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,444);
INSERT INTO shopping_cart(user_id, product_id) VALUES(10,210);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(10,196,2,'store money','Santar�m, Esmoriz, Avenida das Palmeiras, 8652-361','transportation','FALSE','2014-06-24 19:38:36+08','2014-07-19 01:30:51+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,496);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,94);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,408);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(21,6,3,'store money','Braga, Loul�, Rua dos Ger�nios, 9681-898','order','TRUE','2018-01-12 15:16:41+012','2018-02-09 15:41:32+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,222);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,154);
INSERT INTO shopping_cart(user_id, product_id) VALUES(12,456);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(12,135,3,'store money','Guarda, Amarante, Pra�a das Papoilas, 6190-703','order','FALSE','2015-08-11 13:18:28+012','2015-09-04 21:47:05+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,500);
INSERT INTO shopping_cart(user_id, product_id) VALUES(80,399);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(80,48,2,'store money','Leiria, Bragan�a, Rua da Harmonia, 3803-689','delivered','TRUE','2004-04-09 17:09:06+03','2004-04-24 14:20:29+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,9);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,344);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,432);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,11);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(60,164,4,'credit/debit card','Portalegre, Barreiro, Rua da Amendoeira, 3881-402','delivered','FALSE','2020-07-13 06:27:13+03','2020-07-23 08:15:42+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,35);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,260);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,349);
INSERT INTO shopping_cart(user_id, product_id) VALUES(55,353);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(55,212,4,'store money','Porto, Odivelas, Largo da Cam�lia, 1318-129','transportation','TRUE','2000-05-08 09:24:54+00','2000-06-06 08:24:04+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,40);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,6);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,354);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,256);
INSERT INTO shopping_cart(user_id, product_id) VALUES(74,138);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(74,355,5,'credit/debit card','Portalegre, Elvas, Rua das Rosas, 7299-727','payment','FALSE','2007-08-14 14:39:06+08','2007-09-09 09:53:24+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,428);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,206);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,493);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,344);
INSERT INTO shopping_cart(user_id, product_id) VALUES(6,298);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(6,65,5,'credit/debit card','Vila Real, Covilh�, Rua da Fraternidade, 8089-610','payment','FALSE','2022-01-31 12:11:05+00','2022-02-15 16:55:14+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,491);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,367);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,430);
INSERT INTO shopping_cart(user_id, product_id) VALUES(69,153);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(69,212,4,'paypal','Viseu, Santa Maria da Feira, Rua da Lapa, 7341-542','delivered','TRUE','2013-09-21 04:47:29+011','2013-09-30 13:07:49+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,237);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,159);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,372);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,173);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(89,192,4,'credit/debit card','Porto, Paredes, Rua da Fonte, 626-673','order','TRUE','2009-01-14 05:37:18+04','2009-01-17 16:46:06+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,483);
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,398);
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,79);
INSERT INTO shopping_cart(user_id, product_id) VALUES(93,493);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(93,224,4,'store money','Vila Real, Loures, Rua dos Pinheiros, 3875-145','order','TRUE','2013-04-17 13:50:25+04','2013-04-28 17:11:14+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,44);
INSERT INTO shopping_cart(user_id, product_id) VALUES(76,271);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(76,48,2,'paypal','Castelo Branco, Fafe, Rua das Rosas, 6350-683','transportation','FALSE','2020-01-26 20:36:48+08','2020-02-17 05:52:50+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,359);
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,233);
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,478);
INSERT INTO shopping_cart(user_id, product_id) VALUES(85,489);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(85,60,4,'store money','Coimbra, Rio Maior, Rua dos Choupos, 267-855','order','TRUE','2016-01-27 12:05:03+05','2016-01-28 13:08:30+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,313);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,303);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,322);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,400);
INSERT INTO shopping_cart(user_id, product_id) VALUES(40,88);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(40,210,5,'paypal','Viseu, Almada, Rua das Glic�nias, 8891-149','order','FALSE','2011-08-20 04:01:52+01','2011-09-06 13:51:53+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,97);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,3);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,10);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(62,27,3,'store money','Portalegre, Amadora, Travessa das Flores, 2187-474','delivered','TRUE','2013-12-14 22:38:14+01','2014-01-15 23:11:46+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,101);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,230);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,70);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(60,195,3,'credit/debit card','Viana do Castelo, Gondomar, Rua dos Pinheiros, 7901-192','order','FALSE','2018-04-01 09:47:57+00','2018-05-03 14:48:20+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,397);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,493);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,482);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,465);
INSERT INTO shopping_cart(user_id, product_id) VALUES(19,481);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(19,485,5,'credit/debit card','Aveiro, Lagos, Rua da Bica, 8136-975','order','FALSE','2013-08-24 09:59:07+011','2013-09-26 21:32:14+011');
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,403);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,299);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,189);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(17,54,3,'credit/debit card','Bragan�a, Bragan�a, Rua da Alfazema, 3480-161','payment','TRUE','2014-07-25 14:33:12+09','2014-08-14 03:39:32+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,266);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,249);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,127);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,310);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(8,180,4,'store money','Castelo Branco, Chaves, Pra�a do Marqu�s, 2972-446','order','FALSE','2003-04-06 14:47:10+09','2003-04-13 07:05:52+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,399);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,478);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,120);
INSERT INTO shopping_cart(user_id, product_id) VALUES(96,416);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(96,308,4,'paypal','Guarda, Santo Tirso, Avenida das Margaridas, 7655-130','order','TRUE','2011-06-18 05:07:53+08','2011-07-02 18:41:05+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,155);
INSERT INTO shopping_cart(user_id, product_id) VALUES(9,175);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(9,30,2,'credit/debit card','Lisboa, Tomar, Rua da Aldeia, 8640-489','payment','FALSE','2006-03-24 09:59:56+02','2006-04-11 12:02:32+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,191);
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,215);
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,310);
INSERT INTO shopping_cart(user_id, product_id) VALUES(71,239);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(71,220,4,'credit/debit card','Viana do Castelo, Amarante, Avenida da Sustentabilidade, 8672-732','transportation','TRUE','2005-01-04 13:53:06+03','2005-01-31 11:54:53+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(35,77);
INSERT INTO shopping_cart(user_id, product_id) VALUES(35,251);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(35,104,2,'paypal','Vila Real, Santo Tirso, Rua da Amendoeira, 856-208','delivered','TRUE','2001-05-15 01:53:55+01','2001-05-27 15:17:39+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,207);
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,382);
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,305);
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,74);
INSERT INTO shopping_cart(user_id, product_id) VALUES(24,250);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(24,155,5,'store money','Set�bal, Matosinhos, Rua da Solidariedade, 7693-172','payment','TRUE','2023-03-11 10:25:56+07','2023-04-06 02:48:44+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,402);
INSERT INTO shopping_cart(user_id, product_id) VALUES(62,187);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(62,150,2,'paypal','Viseu, Almada, Rua das Beg�nias, 6711-577','delivered','TRUE','2023-06-02 22:07:22+09','2023-07-03 02:51:54+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,62);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,301);
INSERT INTO shopping_cart(user_id, product_id) VALUES(15,350);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(15,96,3,'store money','Aveiro, Vila Nova de Gaia, Rua das Hort�nsias, 8038-319','delivered','TRUE','2021-12-06 13:58:07+04','2022-01-09 21:28:38+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(88,462);
INSERT INTO shopping_cart(user_id, product_id) VALUES(88,20);
INSERT INTO shopping_cart(user_id, product_id) VALUES(88,268);
INSERT INTO shopping_cart(user_id, product_id) VALUES(88,55);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(88,380,4,'credit/debit card','Coimbra, Tavira, Rua do Riacho, 2435-148','delivered','TRUE','2000-11-01 03:20:05+03','2000-11-06 04:54:06+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,79);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,129);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,97);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,452);
INSERT INTO shopping_cart(user_id, product_id) VALUES(98,83);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(98,215,5,'paypal','Vila Real, Valongo, Rua da Encosta, 8486-892','payment','FALSE','2000-03-12 14:31:41+00','2000-03-27 03:16:50+00');
INSERT INTO shopping_cart(user_id, product_id) VALUES(57,456);
INSERT INTO shopping_cart(user_id, product_id) VALUES(57,296);
INSERT INTO shopping_cart(user_id, product_id) VALUES(57,476);
INSERT INTO shopping_cart(user_id, product_id) VALUES(57,437);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(57,212,4,'credit/debit card','Porto, Vila do Conde, Avenida da Paz, 9643-223','transportation','TRUE','2010-02-05 04:00:07+03','2010-02-25 14:45:22+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,442);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,254);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,67);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(60,165,3,'paypal','Guarda, Penafiel, Rua das Hort�nsias, 2172-568','transportation','FALSE','2022-08-15 01:32:31+010','2022-08-28 20:13:21+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,460);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,379);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,40);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,51);
INSERT INTO shopping_cart(user_id, product_id) VALUES(17,470);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(17,50,5,'store money','Leiria, Santa Maria da Feira, Avenida da Democracia, 4227-832','transportation','FALSE','2002-11-01 04:11:39+03','2002-11-24 04:32:58+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(72,439);
INSERT INTO shopping_cart(user_id, product_id) VALUES(72,89);
INSERT INTO shopping_cart(user_id, product_id) VALUES(72,171);
INSERT INTO shopping_cart(user_id, product_id) VALUES(72,410);
INSERT INTO shopping_cart(user_id, product_id) VALUES(72,305);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(72,270,5,'store money','Guarda, Vila Nova de Gaia, Rua dos Jardins, 794-165','delivered','FALSE','2006-02-19 23:10:28+012','2006-03-14 09:37:47+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,493);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,122);
INSERT INTO shopping_cart(user_id, product_id) VALUES(68,275);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(68,57,3,'credit/debit card','Castelo Branco, Santa Maria da Feira, Largo dos Castanheiros, 9022-880','order','FALSE','2006-06-06 04:33:21+03','2006-06-10 04:02:25+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,13);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,258);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,458);
INSERT INTO shopping_cart(user_id, product_id) VALUES(92,253);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(92,372,4,'credit/debit card','Beja, Beira-Mar, Rua da Esperan�a, 149-202','delivered','TRUE','2006-10-25 23:34:32+08','2006-10-28 18:51:03+08');
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,206);
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,5);
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,212);
INSERT INTO shopping_cart(user_id, product_id) VALUES(50,83);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(50,48,4,'paypal','Faro, Oeiras, Pra�a das Papoilas, 525-463','delivered','FALSE','2008-02-24 11:43:17+07','2008-03-26 11:43:55+07');
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,130);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,179);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,158);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,273);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,14);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(90,25,5,'store money','Coimbra, Caldas da Rainha, Pra�a das Beg�nias, 9683-899','order','TRUE','2001-06-13 11:00:18+09','2001-07-08 11:50:28+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,55);
INSERT INTO shopping_cart(user_id, product_id) VALUES(60,483);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(60,68,2,'paypal','�vora, Chaves, Rua dos Navegadores, 2901-184','payment','FALSE','2022-12-22 13:30:25+03','2023-01-23 18:29:09+03');
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,358);
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,103);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(18,166,2,'store money','Bragan�a, Lamego, Avenida do Atl�ntico, 2906-345','transportation','TRUE','2020-02-05 20:40:20+04','2020-03-02 10:41:46+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,262);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,297);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,22);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,286);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(47,256,4,'paypal','Viseu, Vila Real de Santo Ant�nio, Rua dos Cedros, 9805-431','order','FALSE','2004-08-08 05:52:54+012','2004-09-03 11:02:02+012');
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,26);
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,285);
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,153);
INSERT INTO shopping_cart(user_id, product_id) VALUES(99,490);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(99,132,4,'store money','Viseu, Penafiel, Pra�a das Cam�lias, 9760-479','transportation','TRUE','2014-08-09 09:25:14+02','2014-08-26 06:44:04+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,476);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,154);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,106);
INSERT INTO shopping_cart(user_id, product_id) VALUES(7,224);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(7,184,4,'paypal','Coimbra, �gueda, Rua das Giestas, 4496-582','delivered','TRUE','2006-11-25 00:19:54+06','2006-12-20 19:04:38+06');
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,331);
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,41);
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,32);
INSERT INTO shopping_cart(user_id, product_id) VALUES(65,359);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(65,56,4,'credit/debit card','Coimbra, Amarante, Rua da Harmonia, 4069-911','payment','FALSE','2020-04-03 02:07:41+01','2020-04-09 19:17:01+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,20);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,389);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(28,38,2,'paypal','Aveiro, Esposende, Rua de S�o Jo�o, 5826-630','transportation','FALSE','2001-06-18 11:50:38+010','2001-07-16 05:37:14+010');
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,125);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,99);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,126);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,97);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(26,296,4,'credit/debit card','Porto, Estoril, Rua da Esperan�a, 7242-654','transportation','FALSE','2002-12-02 16:05:04+05','2002-12-25 12:56:06+05');
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,17);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,241);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,150);
INSERT INTO shopping_cart(user_id, product_id) VALUES(8,251);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(8,248,4,'credit/debit card','Portalegre, Rio Maior, Pra�a da Alegria, 9766-413','transportation','TRUE','2002-06-25 02:49:23+04','2002-06-25 12:49:05+04');
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,492);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,63);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,365);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,391);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,125);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(47,320,5,'paypal','Santar�m, Lamego, Avenida das Flores, 8834-927','order','TRUE','2009-03-31 06:24:07+09','2009-04-07 17:35:46+09');
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,334);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,164);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,397);
INSERT INTO shopping_cart(user_id, product_id) VALUES(21,215);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(21,84,4,'paypal','Santar�m, Elvas, Rua da Escola, 7705-195','delivered','TRUE','2011-12-27 04:56:40+02','2012-01-07 17:07:50+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(29,276);
INSERT INTO shopping_cart(user_id, product_id) VALUES(29,300);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(29,182,2,'paypal','Vila Real, Beira-Mar, Rua dos Pinheiros, 5318-585','order','TRUE','2022-07-31 15:11:08+02','2022-08-11 15:41:38+02');
INSERT INTO shopping_cart(user_id, product_id) VALUES(42,221);
INSERT INTO shopping_cart(user_id, product_id) VALUES(42,224);
INSERT INTO shopping_cart(user_id, product_id) VALUES(42,337);
INSERT INTO shopping_cart(user_id, product_id) VALUES(42,31);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(42,228,4,'store money','Set�bal, Castelo de Vide, Rua de Santa Catarina, 3981-471','order','FALSE','2001-12-24 01:15:38+01','2002-01-15 07:00:17+01');
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,445);
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,228);
INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,isTracked,orderedAt,orderArrivedAt) VALUES(18,70,2,'credit/debit card','Santar�m, Covilh�, Rua da Esperan�a, 2841-162','payment','FALSE','2006-06-10 07:13:59+01','2006-06-25 15:45:27+01');

INSERT INTO shopping_cart(user_id, product_id) VALUES(89,341);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,163);
INSERT INTO shopping_cart(user_id, product_id) VALUES(89,440);
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,445);
INSERT INTO shopping_cart(user_id, product_id) VALUES(18,228);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,492);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,63);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,365);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,391);
INSERT INTO shopping_cart(user_id, product_id) VALUES(47,125);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,20);
INSERT INTO shopping_cart(user_id, product_id) VALUES(28,389);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,125);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,99);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,126);
INSERT INTO shopping_cart(user_id, product_id) VALUES(26,97);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,130);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,179);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,158);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,273);
INSERT INTO shopping_cart(user_id, product_id) VALUES(90,14);

INSERT INTO wishlist(user_id, product_id) VALUES(5,435);
INSERT INTO wishlist(user_id, product_id) VALUES(6,162);
INSERT INTO wishlist(user_id, product_id) VALUES(7,360);
INSERT INTO wishlist(user_id, product_id) VALUES(8,69);
INSERT INTO wishlist(user_id, product_id) VALUES(9,98);
INSERT INTO wishlist(user_id, product_id) VALUES(10,340);
INSERT INTO wishlist(user_id, product_id) VALUES(11,268);
INSERT INTO wishlist(user_id, product_id) VALUES(12,208);
INSERT INTO wishlist(user_id, product_id) VALUES(13,213);
INSERT INTO wishlist(user_id, product_id) VALUES(14,316);
INSERT INTO wishlist(user_id, product_id) VALUES(15,309);
INSERT INTO wishlist(user_id, product_id) VALUES(16,176);
INSERT INTO wishlist(user_id, product_id) VALUES(17,236);
INSERT INTO wishlist(user_id, product_id) VALUES(18,338);
INSERT INTO wishlist(user_id, product_id) VALUES(19,101);
INSERT INTO wishlist(user_id, product_id) VALUES(20,127);
INSERT INTO wishlist(user_id, product_id) VALUES(21,453);
INSERT INTO wishlist(user_id, product_id) VALUES(22,240);
INSERT INTO wishlist(user_id, product_id) VALUES(23,469);
INSERT INTO wishlist(user_id, product_id) VALUES(24,213);
INSERT INTO wishlist(user_id, product_id) VALUES(25,110);
INSERT INTO wishlist(user_id, product_id) VALUES(26,123);
INSERT INTO wishlist(user_id, product_id) VALUES(27,395);
INSERT INTO wishlist(user_id, product_id) VALUES(28,266);
INSERT INTO wishlist(user_id, product_id) VALUES(29,269);
INSERT INTO wishlist(user_id, product_id) VALUES(30,319);
INSERT INTO wishlist(user_id, product_id) VALUES(31,159);
INSERT INTO wishlist(user_id, product_id) VALUES(32,80);
INSERT INTO wishlist(user_id, product_id) VALUES(33,70);
INSERT INTO wishlist(user_id, product_id) VALUES(34,106);
INSERT INTO wishlist(user_id, product_id) VALUES(35,283);
INSERT INTO wishlist(user_id, product_id) VALUES(36,310);
INSERT INTO wishlist(user_id, product_id) VALUES(37,52);
INSERT INTO wishlist(user_id, product_id) VALUES(38,463);
INSERT INTO wishlist(user_id, product_id) VALUES(39,440);
INSERT INTO wishlist(user_id, product_id) VALUES(40,218);
INSERT INTO wishlist(user_id, product_id) VALUES(41,267);
INSERT INTO wishlist(user_id, product_id) VALUES(42,306);
INSERT INTO wishlist(user_id, product_id) VALUES(43,159);
INSERT INTO wishlist(user_id, product_id) VALUES(44,311);
INSERT INTO wishlist(user_id, product_id) VALUES(45,229);
INSERT INTO wishlist(user_id, product_id) VALUES(46,411);
INSERT INTO wishlist(user_id, product_id) VALUES(47,370);
INSERT INTO wishlist(user_id, product_id) VALUES(48,259);
INSERT INTO wishlist(user_id, product_id) VALUES(49,421);
INSERT INTO wishlist(user_id, product_id) VALUES(50,286);
INSERT INTO wishlist(user_id, product_id) VALUES(51,227);
INSERT INTO wishlist(user_id, product_id) VALUES(52,260);
INSERT INTO wishlist(user_id, product_id) VALUES(53,338);
INSERT INTO wishlist(user_id, product_id) VALUES(54,73);
INSERT INTO wishlist(user_id, product_id) VALUES(55,366);
INSERT INTO wishlist(user_id, product_id) VALUES(56,246);
INSERT INTO wishlist(user_id, product_id) VALUES(57,210);
INSERT INTO wishlist(user_id, product_id) VALUES(58,377);
INSERT INTO wishlist(user_id, product_id) VALUES(59,309);
INSERT INTO wishlist(user_id, product_id) VALUES(60,212);
INSERT INTO wishlist(user_id, product_id) VALUES(61,259);
INSERT INTO wishlist(user_id, product_id) VALUES(62,294);
INSERT INTO wishlist(user_id, product_id) VALUES(63,236);
INSERT INTO wishlist(user_id, product_id) VALUES(64,170);
INSERT INTO wishlist(user_id, product_id) VALUES(65,304);
INSERT INTO wishlist(user_id, product_id) VALUES(66,88);
INSERT INTO wishlist(user_id, product_id) VALUES(67,441);
INSERT INTO wishlist(user_id, product_id) VALUES(68,91);
INSERT INTO wishlist(user_id, product_id) VALUES(69,149);
INSERT INTO wishlist(user_id, product_id) VALUES(70,374);
INSERT INTO wishlist(user_id, product_id) VALUES(71,319);
INSERT INTO wishlist(user_id, product_id) VALUES(72,25);
INSERT INTO wishlist(user_id, product_id) VALUES(73,268);
INSERT INTO wishlist(user_id, product_id) VALUES(74,134);
INSERT INTO wishlist(user_id, product_id) VALUES(75,405);
INSERT INTO wishlist(user_id, product_id) VALUES(76,300);
INSERT INTO wishlist(user_id, product_id) VALUES(77,419);
INSERT INTO wishlist(user_id, product_id) VALUES(78,220);
INSERT INTO wishlist(user_id, product_id) VALUES(79,198);
INSERT INTO wishlist(user_id, product_id) VALUES(80,370);
INSERT INTO wishlist(user_id, product_id) VALUES(81,448);
INSERT INTO wishlist(user_id, product_id) VALUES(82,116);
INSERT INTO wishlist(user_id, product_id) VALUES(83,305);
INSERT INTO wishlist(user_id, product_id) VALUES(84,345);
INSERT INTO wishlist(user_id, product_id) VALUES(85,166);
INSERT INTO wishlist(user_id, product_id) VALUES(86,312);
INSERT INTO wishlist(user_id, product_id) VALUES(87,432);
INSERT INTO wishlist(user_id, product_id) VALUES(88,326);
INSERT INTO wishlist(user_id, product_id) VALUES(89,318);
INSERT INTO wishlist(user_id, product_id) VALUES(90,45);
INSERT INTO wishlist(user_id, product_id) VALUES(91,431);
INSERT INTO wishlist(user_id, product_id) VALUES(92,148);
INSERT INTO wishlist(user_id, product_id) VALUES(93,88);
INSERT INTO wishlist(user_id, product_id) VALUES(94,159);
INSERT INTO wishlist(user_id, product_id) VALUES(95,101);
INSERT INTO wishlist(user_id, product_id) VALUES(96,293);
INSERT INTO wishlist(user_id, product_id) VALUES(97,57);
INSERT INTO wishlist(user_id, product_id) VALUES(98,121);
INSERT INTO wishlist(user_id, product_id) VALUES(99,231);

INSERT INTO product_category(product_id,category_type) VALUES(1,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(2,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(3,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(4,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(5,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(6,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(7,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(8,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(9,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(10,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(11,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(12,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(13,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(14,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(15,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(16,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(17,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(18,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(19,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(20,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(21,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(22,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(23,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(24,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(25,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(26,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(27,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(28,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(29,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(30,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(31,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(32,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(33,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(34,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(35,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(36,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(37,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(38,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(39,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(40,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(41,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(42,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(43,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(44,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(45,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(46,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(47,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(48,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(49,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(50,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(51,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(52,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(53,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(54,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(55,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(56,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(57,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(58,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(59,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(60,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(61,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(62,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(63,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(64,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(65,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(66,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(67,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(68,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(69,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(70,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(71,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(72,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(73,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(74,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(75,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(76,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(77,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(78,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(79,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(80,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(81,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(82,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(83,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(84,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(85,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(86,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(87,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(88,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(89,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(90,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(91,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(92,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(93,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(94,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(95,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(96,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(97,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(98,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(99,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(100,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(101,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(102,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(103,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(104,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(105,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(106,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(107,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(108,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(109,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(110,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(111,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(112,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(113,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(114,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(115,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(116,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(117,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(118,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(119,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(120,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(121,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(122,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(123,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(124,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(125,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(126,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(127,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(128,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(129,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(130,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(131,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(132,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(133,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(134,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(135,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(136,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(137,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(138,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(139,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(140,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(141,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(142,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(143,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(144,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(145,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(146,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(147,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(148,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(149,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(150,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(151,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(152,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(153,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(154,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(155,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(156,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(157,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(158,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(159,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(160,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(161,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(162,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(163,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(164,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(165,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(166,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(167,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(168,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(169,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(170,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(171,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(172,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(173,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(174,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(175,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(176,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(177,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(178,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(179,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(180,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(181,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(182,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(183,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(184,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(185,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(186,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(187,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(188,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(189,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(190,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(191,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(192,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(193,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(194,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(195,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(196,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(197,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(198,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(199,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(200,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(201,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(202,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(203,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(204,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(205,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(206,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(207,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(208,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(209,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(210,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(211,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(212,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(213,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(214,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(215,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(216,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(217,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(218,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(219,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(220,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(221,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(222,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(223,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(224,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(225,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(226,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(227,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(228,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(229,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(230,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(231,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(232,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(233,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(234,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(235,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(236,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(237,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(238,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(239,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(240,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(241,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(242,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(243,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(244,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(245,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(246,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(247,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(248,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(249,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(250,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(251,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(252,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(253,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(254,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(255,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(256,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(257,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(258,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(259,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(260,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(261,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(262,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(263,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(264,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(265,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(266,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(267,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(268,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(269,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(270,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(271,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(272,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(273,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(274,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(275,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(276,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(277,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(278,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(279,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(280,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(281,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(282,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(283,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(284,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(285,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(286,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(287,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(288,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(289,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(290,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(291,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(292,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(293,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(294,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(295,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(296,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(297,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(298,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(299,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(300,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(301,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(302,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(303,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(304,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(305,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(306,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(307,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(308,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(309,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(310,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(311,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(312,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(313,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(314,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(315,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(316,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(317,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(318,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(319,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(320,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(321,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(322,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(323,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(324,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(325,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(326,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(327,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(328,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(329,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(330,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(331,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(332,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(333,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(334,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(335,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(336,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(337,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(338,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(339,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(340,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(341,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(342,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(343,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(344,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(345,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(346,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(347,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(348,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(349,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(350,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(351,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(352,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(353,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(354,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(355,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(356,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(357,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(358,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(359,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(360,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(361,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(362,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(363,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(364,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(365,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(366,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(367,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(368,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(369,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(370,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(371,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(372,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(373,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(374,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(375,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(376,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(377,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(378,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(379,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(380,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(381,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(382,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(383,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(384,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(385,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(386,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(387,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(388,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(389,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(390,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(391,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(392,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(393,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(394,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(395,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(396,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(397,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(398,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(399,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(400,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(401,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(402,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(403,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(404,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(405,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(406,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(407,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(408,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(409,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(410,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(411,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(412,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(413,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(414,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(415,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(416,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(417,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(418,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(419,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(420,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(421,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(422,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(423,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(424,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(425,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(426,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(427,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(428,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(429,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(430,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(431,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(432,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(433,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(434,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(435,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(436,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(437,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(438,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(439,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(440,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(441,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(442,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(443,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(444,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(445,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(446,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(447,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(448,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(449,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(450,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(451,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(452,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(453,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(454,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(455,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(456,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(457,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(458,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(459,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(460,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(461,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(462,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(463,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(464,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(465,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(466,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(467,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(468,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(469,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(470,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(471,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(472,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(473,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(474,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(475,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(476,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(477,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(478,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(479,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(480,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(481,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(482,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(483,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(484,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(485,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(486,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(487,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(488,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(489,'romance');
INSERT INTO product_category(product_id,category_type) VALUES(490,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(491,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(492,'mystery');
INSERT INTO product_category(product_id,category_type) VALUES(493,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(494,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(495,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(496,'non-fiction');
INSERT INTO product_category(product_id,category_type) VALUES(497,'fiction');
INSERT INTO product_category(product_id,category_type) VALUES(498,'comics');
INSERT INTO product_category(product_id,category_type) VALUES(499,'horror');
INSERT INTO product_category(product_id,category_type) VALUES(500,'non-fiction');

INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(48,104,'Enchantment Dragon Aurora Enchantment Mystery','Jumping Eating Firefly Cascade Eating Bicycle Trampoline Butterfly Rainbow Starlight Symphony Reading Potion Rainbow Apple Sleeping Dancing Echo Horizon Opulent',4,'2018-06-07 01:56:27+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(76,478,'Euphoria Quicksilver Lighthouse Bicycle Aurora','Singing Moonlight Sunshine Trampoline Singing Symphony Quicksilver Apple Apple Chocolate Dragon Treasure Saffron Cascade Serenade Apple Dancing Singing Dragon Sleeping',1,'2010-02-28 16:12:54+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(60,419,'Singing Tranquility Quicksilver Firefly Whimsical','Telescope Carnival Zephyr Cascade Running Piano Lighthouse Rainbow Mountain Euphoria Dancing Dream Writing Reading Singing Telescope Starlight Carnival Mirage Tranquility',4,'2015-06-19 21:28:43+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(92,206,'Tranquility Reading Adventure Tranquility Harmony','Quicksilver Moonlight Serenade Harmony Mystery Harmony Dancing Castle Eating Cascade Secret Trampoline Apple Horizon Carnival Carousel Firefly Trampoline Sleeping Serenade',5,'2003-07-09 04:58:12+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(46,418,'Galaxy Running Butterfly Cascade Serendipity','Chocolate Sunshine Piano Moonlight Starlight Whimsical Galaxy Mountain Rainbow Aurora Cascade Mirage Moonlight Whimsical Rainbow Bicycle Opulent Bamboo Singing Carnival',4,'2003-02-21 01:55:30+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(96,358,'Horizon Whimsical Harmony Potion Apple','Mirage Enchantment Piano Potion Singing Starlight Velvet Treasure Carnival Lighthouse Treasure Whisper Writing Galaxy Whisper Dragon Thinking Butterfly Reading Moonlight',5,'2004-03-09 11:17:34+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(21,369,'Carousel Carnival Castle Zephyr Euphoria','Radiance Echo Galaxy Serenade Chocolate Aurora Ocean Dragon Radiance Harmony Moonlight Carousel Secret Saffron Opulent Zephyr Mountain Euphoria Thinking Dancing',2,'2023-02-28 17:07:48+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(69,196,'Secret Horizon Aurora Symphony Harmony','Euphoria Ocean Sunshine Velvet Twilight Serenade Sunshine Horizon Dream Tranquility Firefly Enchantment Dancing Running Velvet Mirage Running Adventure Mystery Telescope',3,'2004-09-17 08:27:58+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(18,438,'Running Dream Galaxy Trampoline Tranquility','Velvet Secret Adventure Adventure Euphoria Dragon Dream Dancing Telescope Tranquility Butterfly Bicycle Sunshine Elephant Treasure Harmony Sleeping Mountain Reading Dancing',3,'2019-02-25 21:18:23+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(97,82,'Piano Mountain Running Mirage Firefly','Swimming Dream Piano Piano Eating Singing Ocean Adventure Mystery Rainbow Piano Serenade Thinking Mystery Dancing Twilight Apple Bicycle Ocean Adventure',4,'2013-08-28 10:08:33+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(53,284,'Treasure Tranquility Eating Dream Opulent','Tranquility Velvet Apple Lighthouse Twilight Moonlight Singing Twilight Writing Serendipity Dragon Horizon Lighthouse Quicksilver Mountain Reading Serendipity Starlight Enchantment Quicksilver',5,'2020-04-12 22:12:08+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(73,416,'Carnival Bamboo Bamboo Potion Serendipity','Swimming Mountain Dragon Horizon Moonlight Rainbow Serenade Trampoline Dragon Thinking Galaxy Treasure Twilight Treasure Zephyr Jumping Rainbow Running Rainbow Opulent',2,'2021-06-24 13:00:58+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,96,'Dragon Castle Cascade Butterfly Zephyr','Aurora Telescope Enchantment Jumping Whimsical Aurora Castle Rainbow Butterfly Trampoline Swimming Echo Serenade Reading Potion Treasure Enchantment Euphoria Tranquility Enchantment',1,'2006-09-19 09:54:53+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,3,'Starlight Aurora Sleeping Aurora Reading','Whisper Radiance Saffron Serendipity Mirage Sunshine Thinking Elephant Horizon Eating Tranquility Dragon Potion Treasure Butterfly Writing Thinking Cascade Euphoria Chocolate',2,'2020-11-08 13:45:32+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(27,177,'Whimsical Moonlight Whimsical Ocean Starlight','Mirage Chocolate Potion Chocolate Aurora Reading Telescope Whimsical Trampoline Butterfly Serendipity Galaxy Running Piano Moonlight Saffron Starlight Jumping Opulent Ocean',3,'2003-08-27 08:13:36+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(73,478,'Lighthouse Saffron Enchantment Thinking Starlight','Tranquility Velvet Enchantment Swimming Twilight Castle Swimming Harmony Jumping Jumping Firefly Bicycle Moonlight Dream Dragon Carousel Enchantment Carousel Opulent Trampoline',2,'2003-09-12 10:12:06+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(39,353,'Aurora Trampoline Writing Velvet Firefly','Starlight Velvet Treasure Tranquility Castle Carnival Telescope Firefly Echo Secret Telescope Starlight Whimsical Starlight Piano Carousel Serenade Tranquility Zephyr Velvet',2,'2011-03-22 22:31:48+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(46,367,'Euphoria Firefly Galaxy Radiance Bicycle','Saffron Velvet Piano Eating Radiance Mystery Telescope Sunshine Ocean Horizon Aurora Eating Writing Thinking Thinking Euphoria Moonlight Whisper Castle Treasure',3,'2006-11-08 01:23:41+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(81,214,'Adventure Quicksilver Eating Eating Radiance','Chocolate Singing Serenade Sleeping Radiance Euphoria Eating Dragon Firefly Dancing Whimsical Echo Carousel Piano Euphoria Whisper Sleeping Potion Tranquility Dragon',5,'2002-02-17 03:06:21+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(59,433,'Opulent Secret Symphony Sleeping Adventure','Dream Cascade Ocean Twilight Sunshine Secret Singing Secret Opulent Ocean Cascade Radiance Velvet Aurora Lighthouse Cascade Secret Echo Enchantment Dream',4,'2015-06-23 03:51:11+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(39,435,'Chocolate Tranquility Sleeping Adventure Swimming','Serendipity Chocolate Sunshine Enchantment Whisper Castle Radiance Velvet Galaxy Twilight Firefly Jumping Starlight Harmony Dragon Serendipity Running Serendipity Piano Ocean',3,'2012-10-13 11:37:13+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(87,266,'Reading Twilight Trampoline Ocean Serendipity','Firefly Elephant Mirage Potion Elephant Radiance Secret Mystery Tranquility Chocolate Dream Eating Jumping Opulent Velvet Quicksilver Treasure Starlight Echo Aurora',1,'2019-06-03 17:11:39+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(65,414,'Swimming Serendipity Radiance Firefly Echo','Starlight Serenade Symphony Singing Dragon Jumping Twilight Castle Butterfly Sleeping Whimsical Tranquility Mountain Starlight Lighthouse Reading Chocolate Telescope Eating Chocolate',2,'2001-06-16 22:17:14+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(84,246,'Symphony Mirage Mountain Carnival Dream','Mirage Eating Bicycle Bicycle Twilight Euphoria Lighthouse Castle Quicksilver Carousel Serendipity Sleeping Opulent Tranquility Serendipity Adventure Firefly Sleeping Dream Mountain',5,'2019-07-29 00:51:41+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(99,69,'Serendipity Firefly Whimsical Butterfly Trampoline','Carousel Writing Dream Adventure Potion Sunshine Tranquility Carnival Galaxy Bamboo Chocolate Starlight Writing Horizon Twilight Tranquility Lighthouse Tranquility Serendipity Chocolate',5,'2004-07-08 09:22:36+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(26,33,'Butterfly Whimsical Horizon Castle Mirage','Treasure Starlight Elephant Dancing Zephyr Potion Castle Thinking Galaxy Piano Potion Sunshine Potion Bamboo Mirage Horizon Carousel Lighthouse Potion Rainbow',1,'2005-03-25 22:41:16+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(79,204,'Moonlight Singing Saffron Mountain Secret','Singing Firefly Potion Whimsical Carnival Cascade Sleeping Telescope Velvet Running Piano Radiance Dancing Horizon Secret Zephyr Radiance Velvet Carousel Echo',3,'2010-12-15 19:20:15+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(27,391,'Galaxy Radiance Galaxy Carnival Carnival','Rainbow Cascade Aurora Chocolate Zephyr Thinking Potion Treasure Cascade Telescope Moonlight Velvet Telescope Dream Dragon Whimsical Echo Singing Running Trampoline',5,'2011-03-02 22:09:00+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(72,338,'Carnival Zephyr Adventure Galaxy Serenade','Tranquility Bamboo Jumping Moonlight Harmony Serenade Starlight Trampoline Starlight Quicksilver Whisper Opulent Writing Telescope Enchantment Butterfly Cascade Starlight Mystery Singing',5,'2013-03-05 08:35:13+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(40,494,'Running Jumping Rainbow Moonlight Mystery','Mirage Velvet Singing Harmony Enchantment Singing Serendipity Euphoria Sleeping Reading Dream Dragon Whisper Dancing Butterfly Mirage Rainbow Harmony Quicksilver Eating',2,'2010-12-25 15:27:25+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(92,494,'Lighthouse Tranquility Echo Saffron Potion','Mystery Running Starlight Potion Carousel Treasure Bamboo Moonlight Ocean Mirage Swimming Starlight Lighthouse Zephyr Jumping Zephyr Sunshine Dream Opulent Tranquility',4,'2017-04-06 02:04:36+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(82,491,'Sleeping Butterfly Castle Castle Mystery','Writing Cascade Serendipity Velvet Starlight Mountain Echo Running Trampoline Elephant Sunshine Carnival Dancing Moonlight Horizon Echo Singing Dancing Adventure Butterfly',4,'2020-01-29 21:07:11+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(38,155,'Radiance Running Velvet Singing Dream','Secret Moonlight Sunshine Serendipity Tranquility Butterfly Ocean Moonlight Swimming Elephant Jumping Sunshine Secret Serendipity Whisper Harmony Rainbow Harmony Writing Reading',2,'2004-02-19 10:55:51+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(35,291,'Dream Singing Enchantment Velvet Zephyr','Tranquility Bicycle Bamboo Running Thinking Starlight Telescope Apple Firefly Sleeping Mystery Lighthouse Firefly Aurora Mirage Quicksilver Swimming Saffron Whisper Harmony',4,'2002-10-30 04:48:40+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(22,180,'Aurora Mystery Carnival Whisper Cascade','Ocean Carnival Serendipity Eating Moonlight Mystery Whisper Cascade Enchantment Bamboo Firefly Treasure Velvet Thinking Horizon Thinking Sunshine Piano Dragon Carousel',2,'2012-07-03 04:56:28+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(56,312,'Velvet Echo Radiance Adventure Echo','Bicycle Reading Telescope Twilight Mystery Twilight Thinking Reading Thinking Potion Ocean Chocolate Euphoria Enchantment Firefly Lighthouse Symphony Whimsical Symphony Velvet',3,'2007-03-09 11:49:34+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(47,42,'Opulent Eating Symphony Sunshine Harmony','Adventure Butterfly Mirage Zephyr Castle Echo Ocean Serenade Aurora Serendipity Singing Adventure Firefly Quicksilver Euphoria Swimming Chocolate Trampoline Galaxy Trampoline',5,'2007-03-20 11:51:20+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(15,413,'Cascade Velvet Mountain Whisper Apple','Starlight Velvet Adventure Thinking Serenade Velvet Running Twilight Bicycle Adventure Bamboo Quicksilver Sleeping Apple Whimsical Opulent Euphoria Cascade Elephant Mountain',2,'2016-07-01 11:01:02+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(51,33,'Chocolate Piano Twilight Apple Bamboo','Cascade Whimsical Saffron Treasure Writing Bamboo Sleeping Butterfly Starlight Euphoria Galaxy Saffron Dream Carousel Apple Running Saffron Enchantment Enchantment Chocolate',1,'2017-09-14 16:46:57+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(40,403,'Dream Tranquility Butterfly Zephyr Echo','Velvet Swimming Mountain Thinking Singing Firefly Serendipity Sleeping Ocean Reading Mirage Aurora Serendipity Butterfly Chocolate Velvet Ocean Apple Eating Mirage',2,'2007-11-07 16:22:46+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(76,437,'Dancing Opulent Enchantment Dream Sleeping','Firefly Quicksilver Tranquility Harmony Trampoline Horizon Velvet Whisper Velvet Euphoria Euphoria Velvet Eating Elephant Sunshine Velvet Treasure Starlight Twilight Carnival',3,'2021-03-05 00:30:00+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(44,137,'Zephyr Rainbow Bicycle Swimming Sunshine','Galaxy Telescope Whisper Saffron Dancing Cascade Rainbow Secret Harmony Galaxy Zephyr Jumping Running Secret Running Swimming Quicksilver Apple Butterfly Echo',1,'2010-12-10 22:17:36+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(75,310,'Galaxy Dream Cascade Telescope Tranquility','Twilight Aurora Secret Serendipity Serendipity Carousel Sunshine Whimsical Quicksilver Treasure Saffron Horizon Twilight Writing Carnival Carnival Aurora Thinking Cascade Aurora',5,'2016-10-26 20:41:59+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(14,65,'Thinking Moonlight Aurora Carnival Singing','Secret Mountain Starlight Elephant Serenade Apple Butterfly Swimming Carnival Dragon Firefly Euphoria Reading Serendipity Apple Eating Twilight Adventure Lighthouse Twilight',2,'2011-04-03 11:47:40+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(32,237,'Carousel Bicycle Reading Zephyr Serenade','Rainbow Telescope Eating Moonlight Firefly Trampoline Whisper Moonlight Harmony Mountain Telescope Telescope Rainbow Singing Mirage Reading Castle Chocolate Mirage Jumping',4,'2008-11-02 18:34:12+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(93,375,'Treasure Thinking Opulent Enchantment Velvet','Dancing Ocean Mirage Echo Horizon Dancing Bamboo Carousel Harmony Elephant Zephyr Thinking Singing Piano Echo Telescope Apple Harmony Harmony Bamboo',4,'2016-07-30 14:30:58+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,61,'Lighthouse Piano Apple Ocean Butterfly','Serenade Secret Apple Butterfly Reading Quicksilver Whimsical Velvet Quicksilver Serenade Galaxy Mystery Eating Rainbow Jumping Reading Quicksilver Euphoria Eating Velvet',1,'2011-11-06 12:24:04+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(73,241,'Euphoria Lighthouse Mystery Mirage Serenade','Whisper Castle Trampoline Sleeping Firefly Moonlight Aurora Carnival Enchantment Carousel Firefly Moonlight Galaxy Mountain Dancing Galaxy Harmony Horizon Twilight Quicksilver',4,'2004-10-05 08:03:33+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(44,327,'Potion Carousel Apple Starlight Chocolate','Velvet Carnival Reading Quicksilver Tranquility Mountain Twilight Serenade Ocean Elephant Lighthouse Apple Mystery Jumping Trampoline Castle Mountain Chocolate Trampoline Mystery',1,'2015-08-09 04:26:04+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(22,157,'Thinking Bicycle Castle Dancing Zephyr','Bamboo Singing Quicksilver Velvet Apple Carnival Echo Carnival Sleeping Thinking Apple Trampoline Cascade Piano Euphoria Butterfly Velvet Swimming Sunshine Treasure',4,'2009-03-10 07:05:23+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(30,471,'Dragon Carousel Dream Symphony Telescope','Tranquility Mystery Harmony Dream Sunshine Aurora Jumping Serenade Horizon Apple Galaxy Aurora Euphoria Radiance Mirage Adventure Treasure Singing Adventure Quicksilver',5,'2008-09-26 19:19:46+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(88,262,'Serenade Saffron Whisper Firefly Singing','Castle Horizon Opulent Chocolate Aurora Horizon Aurora Mystery Quicksilver Whisper Twilight Radiance Galaxy Firefly Dragon Echo Lighthouse Bicycle Dream Firefly',4,'2020-12-23 22:23:47+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,224,'Sleeping Piano Galaxy Rainbow Piano','Ocean Harmony Velvet Serendipity Euphoria Bamboo Secret Mystery Velvet Aurora Dream Writing Horizon Running Symphony Radiance Serendipity Eating Trampoline Zephyr',3,'2021-06-26 06:10:16+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(67,375,'Treasure Trampoline Serendipity Dancing Lighthouse','Treasure Moonlight Cascade Galaxy Trampoline Eating Velvet Cascade Mountain Radiance Carousel Euphoria Dancing Lighthouse Cascade Harmony Telescope Mirage Enchantment Bamboo',1,'2016-07-11 02:26:49+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(68,218,'Opulent Running Radiance Horizon Cascade','Whimsical Whisper Zephyr Castle Eating Cascade Mountain Telescope Reading Jumping Secret Sleeping Apple Dream Opulent Tranquility Trampoline Harmony Quicksilver Castle',1,'2012-12-09 02:50:20+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(83,68,'Bamboo Rainbow Zephyr Butterfly Saffron','Sunshine Enchantment Opulent Horizon Twilight Echo Ocean Euphoria Adventure Eating Whisper Reading Echo Jumping Thinking Velvet Carnival Starlight Symphony Saffron',4,'2020-03-14 08:28:13+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(65,209,'Piano Enchantment Bicycle Treasure Serenade','Telescope Carousel Quicksilver Mystery Dragon Horizon Butterfly Zephyr Velvet Moonlight Piano Carnival Aurora Treasure Jumping Running Jumping Bicycle Quicksilver Thinking',5,'2002-08-14 03:47:01+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(78,107,'Bamboo Mountain Piano Symphony Ocean','Rainbow Sleeping Opulent Saffron Potion Symphony Secret Elephant Mountain Starlight Sleeping Serenade Serendipity Mystery Opulent Dream Whimsical Bamboo Trampoline Bamboo',1,'2020-02-07 19:14:27+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(30,418,'Swimming Radiance Dream Moonlight Writing','Cascade Reading Echo Carnival Carousel Symphony Secret Whisper Mountain Moonlight Bamboo Tranquility Adventure Galaxy Serendipity Enchantment Castle Adventure Bicycle Dream',2,'2011-11-14 13:42:17+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(98,128,'Mountain Mystery Sunshine Serendipity Serenade','Echo Starlight Radiance Starlight Mirage Carnival Butterfly Harmony Castle Bicycle Galaxy Carnival Rainbow Mystery Elephant Whimsical Telescope Eating Lighthouse Velvet',3,'2005-12-18 11:15:22+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(11,284,'Rainbow Thinking Carousel Mirage Radiance','Swimming Echo Enchantment Singing Reading Writing Saffron Mountain Zephyr Firefly Swimming Aurora Jumping Carousel Apple Chocolate Velvet Opulent Bamboo Cascade',5,'2006-01-11 05:31:30+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(87,423,'Radiance Symphony Thinking Potion Sleeping','Saffron Firefly Trampoline Rainbow Echo Symphony Dancing Aurora Dancing Carnival Singing Eating Rainbow Horizon Firefly Carousel Elephant Sunshine Telescope Jumping',2,'2018-11-17 09:46:27+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(88,335,'Dragon Eating Ocean Trampoline Sunshine','Enchantment Horizon Twilight Symphony Apple Enchantment Mirage Enchantment Dragon Whisper Aurora Harmony Telescope Serendipity Potion Starlight Lighthouse Twilight Carnival Quicksilver',3,'2006-02-12 15:57:49+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(71,172,'Carousel Rainbow Piano Carousel Writing','Adventure Galaxy Carousel Moonlight Whimsical Quicksilver Serendipity Singing Ocean Telescope Swimming Treasure Apple Mirage Opulent Tranquility Sleeping Thinking Mountain Butterfly',2,'2002-09-30 22:25:15+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(94,115,'Euphoria Mirage Sunshine Zephyr Enchantment','Enchantment Bamboo Dream Dragon Jumping Carousel Dream Butterfly Carnival Chocolate Telescope Piano Whisper Serendipity Sleeping Bamboo Lighthouse Aurora Mystery Velvet',4,'2000-03-08 05:58:25+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(54,191,'Serenade Elephant Butterfly Carnival Potion','Firefly Sleeping Cascade Chocolate Serenade Dancing Twilight Apple Swimming Velvet Moonlight Whisper Harmony Euphoria Euphoria Mirage Firefly Apple Harmony Radiance',4,'2016-12-06 07:16:37+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(77,321,'Euphoria Mountain Tranquility Telescope Tranquility','Apple Adventure Radiance Twilight Velvet Lighthouse Symphony Serendipity Enchantment Aurora Echo Serendipity Whisper Moonlight Horizon Mystery Chocolate Velvet Sunshine Saffron',4,'2021-08-19 06:20:42+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(52,104,'Mystery Adventure Saffron Potion Velvet','Harmony Cascade Secret Lighthouse Enchantment Cascade Galaxy Lighthouse Trampoline Telescope Velvet Firefly Castle Harmony Starlight Mirage Adventure Symphony Tranquility Sunshine',1,'2021-05-06 11:48:41+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(39,401,'Galaxy Rainbow Saffron Eating Butterfly','Firefly Jumping Zephyr Rainbow Mountain Chocolate Mystery Whisper Opulent Writing Trampoline Reading Whisper Lighthouse Thinking Aurora Horizon Mystery Enchantment Radiance',2,'2022-07-24 16:02:37+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(28,262,'Piano Swimming Carousel Aurora Harmony','Symphony Mountain Lighthouse Moonlight Serenade Aurora Running Treasure Thinking Bicycle Sleeping Thinking Quicksilver Harmony Jumping Butterfly Harmony Adventure Swimming Opulent',2,'2011-05-22 13:56:31+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(39,198,'Thinking Carousel Quicksilver Butterfly Zephyr','Secret Serenade Elephant Singing Quicksilver Starlight Telescope Zephyr Ocean Reading Opulent Saffron Moonlight Mirage Euphoria Jumping Tranquility Elephant Castle Aurora',1,'2010-02-23 04:29:52+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(18,99,'Jumping Chocolate Bamboo Trampoline Zephyr','Swimming Enchantment Dream Serenade Opulent Apple Symphony Galaxy Butterfly Saffron Sleeping Bamboo Aurora Tranquility Trampoline Aurora Mystery Carousel Echo Lighthouse',3,'2010-10-16 00:18:19+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(71,468,'Whimsical Serendipity Whimsical Symphony Tranquility','Carousel Opulent Serendipity Carousel Echo Apple Dream Apple Opulent Writing Sleeping Twilight Dream Echo Whisper Twilight Lighthouse Secret Tranquility Singing',1,'2004-12-31 23:32:55+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(17,313,'Radiance Carousel Mystery Horizon Euphoria','Firefly Euphoria Thinking Horizon Bamboo Sleeping Rainbow Mirage Enchantment Moonlight Adventure Telescope Starlight Singing Sleeping Jumping Bamboo Dragon Velvet Cascade',5,'2023-12-27 16:16:11+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(29,265,'Sleeping Bicycle Enchantment Whimsical Whisper','Velvet Thinking Moonlight Sleeping Euphoria Saffron Starlight Secret Secret Opulent Serendipity Quicksilver Chocolate Telescope Trampoline Euphoria Bicycle Opulent Radiance Rainbow',4,'2022-07-12 22:43:40+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(44,238,'Echo Serenade Horizon Dancing Singing','Cascade Piano Euphoria Adventure Tranquility Telescope Opulent Symphony Euphoria Firefly Starlight Whisper Tranquility Serenade Running Eating Swimming Elephant Running Twilight',2,'2022-07-20 19:56:48+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(17,379,'Euphoria Telescope Chocolate Swimming Butterfly','Whisper Butterfly Echo Dancing Firefly Serenade Adventure Euphoria Secret Piano Telescope Aurora Whimsical Trampoline Velvet Cascade Firefly Tranquility Bicycle Cascade',1,'2005-07-18 11:00:55+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(6,159,'Carnival Serenade Reading Apple Galaxy','Elephant Rainbow Aurora Rainbow Symphony Castle Horizon Saffron Mountain Zephyr Singing Velvet Opulent Apple Aurora Symphony Galaxy Ocean Euphoria Aurora',2,'2010-12-21 12:43:36+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(11,221,'Rainbow Starlight Sleeping Mirage Secret','Singing Trampoline Thinking Horizon Secret Harmony Ocean Radiance Saffron Twilight Serenade Chocolate Swimming Serenade Mountain Whisper Opulent Enchantment Velvet Chocolate',4,'2015-04-28 10:50:23+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(18,297,'Chocolate Rainbow Telescope Saffron Writing','Harmony Jumping Ocean Adventure Bamboo Dream Rainbow Firefly Butterfly Swimming Aurora Sunshine Mirage Whimsical Whimsical Ocean Sunshine Castle Horizon Telescope',4,'2005-08-13 01:21:30+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(69,212,'Starlight Chocolate Dancing Echo Chocolate','Echo Starlight Adventure Serendipity Carnival Bamboo Cascade Saffron Euphoria Adventure Potion Aurora Whisper Firefly Symphony Rainbow Rainbow Dragon Writing Horizon',1,'2020-07-13 19:56:54+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(78,306,'Enchantment Twilight Thinking Trampoline Running','Apple Singing Treasure Lighthouse Aurora Singing Adventure Bicycle Saffron Thinking Eating Writing Secret Cascade Carnival Ocean Echo Secret Velvet Twilight',2,'2014-12-26 07:08:31+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(29,381,'Jumping Telescope Firefly Eating Velvet','Sleeping Sleeping Twilight Potion Sleeping Secret Serendipity Adventure Cascade Sunshine Firefly Singing Velvet Enchantment Echo Writing Serenade Enchantment Cascade Trampoline',3,'2023-01-14 23:55:10+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(66,424,'Sunshine Serenade Mystery Harmony Dancing','Jumping Velvet Serenade Moonlight Dream Singing Reading Whimsical Bamboo Quicksilver Starlight Zephyr Secret Dream Opulent Aurora Carnival Serendipity Sunshine Singing',2,'2014-02-14 13:17:53+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(55,458,'Jumping Enchantment Serenade Symphony Whimsical','Elephant Galaxy Horizon Mystery Whimsical Dragon Telescope Bamboo Harmony Symphony Whimsical Swimming Symphony Butterfly Swimming Jumping Reading Carnival Secret Horizon',1,'2003-08-29 20:45:36+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(29,195,'Starlight Dream Butterfly Jumping Running','Dragon Running Bicycle Cascade Symphony Zephyr Ocean Rainbow Radiance Saffron Symphony Butterfly Adventure Serendipity Lighthouse Eating Horizon Bicycle Butterfly Tranquility',5,'2020-01-13 13:28:16+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(40,287,'Potion Secret Treasure Swimming Butterfly','Bicycle Chocolate Running Opulent Trampoline Running Twilight Euphoria Euphoria Starlight Running Serendipity Saffron Singing Singing Zephyr Telescope Aurora Harmony Ocean',3,'2010-04-04 22:36:50+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(59,43,'Butterfly Twilight Aurora Singing Harmony','Radiance Galaxy Firefly Aurora Rainbow Telescope Twilight Treasure Singing Galaxy Treasure Running Dream Jumping Velvet Tranquility Carnival Euphoria Tranquility Serendipity',2,'2008-12-25 00:07:23+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(87,289,'Treasure Whimsical Twilight Mirage Whisper','Velvet Twilight Reading Castle Galaxy Firefly Symphony Dream Horizon Velvet Mirage Secret Dragon Dancing Bicycle Treasure Velvet Twilight Lighthouse Moonlight',3,'2000-04-17 00:06:59+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(24,433,'Reading Swimming Bamboo Whisper Bamboo','Reading Tranquility Apple Mirage Euphoria Butterfly Mountain Serenade Whisper Treasure Mountain Sleeping Mountain Potion Serenade Rainbow Aurora Trampoline Whisper Whisper',4,'2003-05-19 18:07:14+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,21,'Lighthouse Horizon Quicksilver Castle Quicksilver','Velvet Harmony Aurora Mountain Sunshine Swimming Carnival Castle Whimsical Zephyr Jumping Saffron Chocolate Lighthouse Running Cascade Zephyr Secret Carnival Enchantment',3,'2010-01-10 11:17:25+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(43,84,'Singing Saffron Radiance Serendipity Dream','Velvet Swimming Starlight Writing Butterfly Mountain Rainbow Galaxy Firefly Elephant Velvet Carnival Mystery Quicksilver Bicycle Serendipity Twilight Dream Potion Mystery',2,'2010-03-05 02:40:02+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(97,53,'Starlight Telescope Treasure Running Enchantment','Ocean Trampoline Castle Cascade Eating Carnival Sleeping Twilight Elephant Opulent Piano Tranquility Symphony Rainbow Telescope Saffron Potion Bamboo Castle Ocean',1,'2019-10-05 04:28:45+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(49,183,'Opulent Zephyr Serendipity Starlight Apple','Lighthouse Bamboo Starlight Whimsical Trampoline Quicksilver Telescope Twilight Mystery Apple Running Quicksilver Whimsical Mountain Dragon Mountain Adventure Rainbow Cascade Firefly',4,'2001-07-15 13:39:32+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(59,64,'Galaxy Symphony Potion Mystery Cascade','Dragon Adventure Sunshine Mystery Zephyr Castle Telescope Velvet Apple Castle Aurora Whisper Piano Ocean Opulent Thinking Piano Cascade Writing Dancing',1,'2021-01-12 17:59:11+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(7,390,'Running Telescope Cascade Chocolate Starlight','Galaxy Lighthouse Elephant Thinking Radiance Carnival Firefly Reading Telescope Aurora Bamboo Secret Galaxy Opulent Eating Sleeping Swimming Adventure Quicksilver Thinking',3,'2006-12-04 17:55:35+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(82,206,'Whisper Writing Running Butterfly Swimming','Whisper Starlight Dancing Piano Firefly Running Piano Running Mystery Mirage Butterfly Chocolate Firefly Chocolate Mirage Dragon Swimming Running Adventure Sunshine',2,'2012-05-28 12:15:27+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(10,149,'Opulent Secret Bamboo Serenade Saffron','Elephant Bamboo Treasure Secret Running Dancing Whimsical Swimming Serendipity Swimming Apple Chocolate Potion Running Mystery Harmony Treasure Potion Whisper Singing',3,'2022-05-08 15:46:15+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(56,322,'Dragon Dancing Apple Lighthouse Singing','Dancing Trampoline Starlight Sleeping Symphony Horizon Sleeping Telescope Eating Carousel Sleeping Moonlight Bamboo Rainbow Trampoline Running Lighthouse Telescope Opulent Echo',4,'2020-05-04 21:53:43+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(10,298,'Sunshine Lighthouse Harmony Running Castle','Tranquility Swimming Mirage Horizon Horizon Reading Dancing Firefly Opulent Horizon Lighthouse Treasure Swimming Writing Rainbow Treasure Piano Trampoline Eating Quicksilver',1,'2014-01-08 14:33:11+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(91,295,'Bamboo Harmony Piano Secret Ocean','Carnival Jumping Starlight Secret Velvet Sunshine Mirage Serendipity Ocean Secret Castle Moonlight Enchantment Opulent Butterfly Writing Tranquility Ocean Serenade Chocolate',5,'2022-01-05 09:43:58+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(12,383,'Cascade Echo Writing Singing Carousel','Rainbow Mystery Cascade Eating Opulent Moonlight Elephant Writing Opulent Firefly Rainbow Whisper Horizon Enchantment Moonlight Serendipity Running Treasure Piano Euphoria',3,'2022-06-24 18:52:38+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(67,161,'Quicksilver Opulent Euphoria Running Piano','Ocean Apple Opulent Lighthouse Starlight Velvet Zephyr Saffron Radiance Piano Carnival Singing Adventure Elephant Whimsical Lighthouse Singing Singing Firefly Horizon',5,'2005-06-27 10:31:43+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(21,488,'Chocolate Writing Cascade Carnival Firefly','Whimsical Galaxy Eating Telescope Eating Tranquility Whisper Rainbow Adventure Opulent Opulent Radiance Ocean Moonlight Singing Mountain Dream Harmony Elephant Chocolate',3,'2002-05-01 19:15:35+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(48,35,'Twilight Mirage Whimsical Tranquility Adventure','Piano Enchantment Serendipity Mirage Serenade Singing Running Telescope Sunshine Aurora Bamboo Swimming Dream Apple Sleeping Potion Cascade Reading Castle Carousel',5,'2011-01-15 11:49:55+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(9,238,'Moonlight Quicksilver Castle Harmony Horizon','Potion Lighthouse Horizon Zephyr Firefly Velvet Singing Opulent Sunshine Chocolate Moonlight Rainbow Sleeping Elephant Carnival Bamboo Trampoline Trampoline Eating Piano',2,'2020-04-11 18:23:16+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(70,39,'Ocean Echo Elephant Horizon Carnival','Horizon Dream Dream Opulent Saffron Writing Whisper Galaxy Ocean Dream Writing Harmony Harmony Trampoline Moonlight Whimsical Elephant Reading Bamboo Telescope',3,'2018-10-02 03:27:57+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(59,118,'Carnival Echo Potion Ocean Quicksilver','Apple Velvet Bicycle Treasure Adventure Castle Opulent Galaxy Mirage Elephant Castle Apple Moonlight Radiance Singing Piano Saffron Mirage Carousel Whisper',5,'2008-09-12 13:30:22+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(97,279,'Carousel Writing Moonlight Cascade Butterfly','Velvet Velvet Velvet Elephant Castle Ocean Serenade Moonlight Saffron Eating Symphony Trampoline Swimming Ocean Jumping Bamboo Symphony Firefly Harmony Horizon',4,'2020-05-09 08:57:42+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(58,221,'Castle Butterfly Echo Butterfly Secret','Piano Echo Telescope Euphoria Firefly Quicksilver Ocean Secret Whisper Radiance Treasure Treasure Bamboo Bicycle Swimming Carousel Chocolate Potion Secret Reading',4,'2017-12-24 00:17:10+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(51,107,'Potion Enchantment Telescope Telescope Castle','Castle Galaxy Firefly Carnival Dancing Horizon Symphony Elephant Dragon Firefly Euphoria Whimsical Echo Apple Horizon Echo Mystery Adventure Trampoline Tranquility',5,'2022-06-10 12:45:14+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(58,338,'Eating Butterfly Velvet Twilight Tranquility','Dancing Apple Starlight Serendipity Saffron Bicycle Adventure Bicycle Chocolate Whimsical Bamboo Starlight Radiance Mystery Writing Whisper Galaxy Rainbow Starlight Dancing',5,'2021-12-26 17:34:18+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(89,27,'Reading Carousel Saffron Apple Swimming','Whimsical Tranquility Whisper Echo Piano Firefly Reading Velvet Rainbow Mountain Velvet Secret Mountain Potion Mountain Serenade Velvet Ocean Serendipity Saffron',4,'2017-12-12 20:44:19+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(71,222,'Dream Symphony Eating Mystery Zephyr','Serendipity Singing Carousel Thinking Swimming Carnival Saffron Symphony Dream Secret Bamboo Mystery Eating Bicycle Eating Secret Whisper Radiance Chocolate Running',2,'2014-04-22 11:07:26+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(5,134,'Horizon Whimsical Aurora Euphoria Opulent','Carousel Bamboo Saffron Trampoline Velvet Eating Lighthouse Trampoline Bamboo Adventure Serendipity Velvet Serendipity Velvet Carnival Writing Piano Adventure Lighthouse Chocolate',4,'2021-07-19 13:04:13+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(29,389,'Moonlight Potion Lighthouse Lighthouse Galaxy','Cascade Jumping Velvet Enchantment Horizon Carnival Twilight Horizon Harmony Writing Opulent Castle Carousel Thinking Radiance Carousel Aurora Treasure Apple Aurora',3,'2001-01-22 06:17:27+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(7,305,'Mirage Dream Telescope Dragon Saffron','Lighthouse Bamboo Carnival Bamboo Whisper Quicksilver Chocolate Thinking Carousel Serenade Mountain Harmony Dream Potion Ocean Secret Radiance Bamboo Horizon Serenade',3,'2013-09-14 03:48:17+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(20,179,'Telescope Bicycle Velvet Starlight Dragon','Dream Dancing Secret Adventure Starlight Castle Horizon Opulent Trampoline Horizon Mountain Writing Whimsical Mirage Mystery Piano Carousel Starlight Euphoria Firefly',5,'2007-07-21 22:34:53+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(7,355,'Rainbow Quicksilver Telescope Chocolate Mountain','Bamboo Jumping Mountain Ocean Zephyr Starlight Secret Castle Mountain Carnival Eating Dragon Euphoria Echo Starlight Writing Mirage Running Whimsical Opulent',3,'2016-02-25 01:04:05+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(11,292,'Piano Saffron Dancing Starlight Secret','Castle Harmony Secret Swimming Chocolate Sunshine Echo Running Apple Carousel Piano Secret Apple Whisper Butterfly Trampoline Reading Writing Moonlight Symphony',3,'2000-04-07 23:10:42+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(92,180,'Harmony Quicksilver Rainbow Serenade Carnival','Mystery Horizon Saffron Rainbow Saffron Radiance Whisper Potion Dancing Cascade Castle Singing Running Mystery Saffron Trampoline Trampoline Whimsical Elephant Castle',5,'2015-01-30 03:01:05+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(19,115,'Dancing Starlight Whimsical Sleeping Symphony','Dragon Writing Dream Zephyr Chocolate Potion Mountain Ocean Symphony Telescope Treasure Eating Serenade Bicycle Whimsical Bamboo Bamboo Running Mirage Serenade',2,'2013-04-28 00:55:27+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(57,237,'Treasure Running Serendipity Cascade Quicksilver','Dream Horizon Echo Reading Lighthouse Starlight Enchantment Dragon Jumping Quicksilver Enchantment Mountain Starlight Horizon Lighthouse Elephant Aurora Echo Telescope Galaxy',3,'2016-09-05 05:19:37+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(7,419,'Dragon Mountain Running Dancing Cascade','Horizon Reading Aurora Writing Serendipity Velvet Running Bicycle Treasure Ocean Trampoline Thinking Sunshine Firefly Piano Bicycle Ocean Horizon Saffron Bicycle',5,'2018-12-29 17:10:22+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(14,154,'Radiance Reading Writing Castle Harmony','Sleeping Ocean Harmony Butterfly Castle Telescope Harmony Ocean Velvet Secret Piano Whimsical Dragon Aurora Moonlight Serendipity Singing Carnival Bicycle Sleeping',2,'2000-05-08 14:23:18+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(52,331,'Rainbow Lighthouse Piano Carousel Firefly','Harmony Piano Mountain Sleeping Writing Opulent Butterfly Galaxy Reading Secret Starlight Apple Reading Mirage Serendipity Starlight Horizon Carousel Lighthouse Zephyr',4,'2010-02-17 11:42:47+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(33,241,'Saffron Running Galaxy Lighthouse Opulent','Sleeping Moonlight Apple Quicksilver Lighthouse Moonlight Bicycle Elephant Mystery Ocean Piano Quicksilver Cascade Serendipity Mirage Velvet Whimsical Writing Mountain Eating',5,'2020-09-09 03:10:03+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(78,168,'Horizon Moonlight Harmony Mystery Enchantment','Firefly Ocean Rainbow Sleeping Enchantment Horizon Lighthouse Harmony Sunshine Firefly Velvet Aurora Aurora Quicksilver Saffron Enchantment Eating Bicycle Running Bamboo',3,'2005-05-08 06:25:54+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(42,240,'Zephyr Dancing Treasure Secret Velvet','Saffron Velvet Velvet Bicycle Running Tranquility Thinking Zephyr Secret Ocean Moonlight Butterfly Reading Firefly Serenade Thinking Swimming Velvet Dragon Harmony',2,'2011-10-06 07:59:01+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(43,229,'Starlight Butterfly Chocolate Thinking Sunshine','Lighthouse Thinking Twilight Dancing Twilight Euphoria Rainbow Chocolate Whisper Radiance Lighthouse Echo Reading Cascade Echo Quicksilver Saffron Quicksilver Dancing Dream',4,'2023-05-30 13:59:02+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(24,304,'Symphony Reading Apple Lighthouse Galaxy','Mountain Swimming Bamboo Tranquility Echo Mountain Zephyr Bicycle Ocean Chocolate Enchantment Adventure Saffron Thinking Symphony Mountain Reading Thinking Eating Serendipity',3,'2023-01-13 07:52:56+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(28,36,'Moonlight Saffron Sunshine Quicksilver Radiance','Opulent Serendipity Singing Starlight Galaxy Apple Euphoria Butterfly Mountain Velvet Secret Jumping Serenade Piano Bicycle Eating Starlight Mystery Lighthouse Carnival',4,'2002-01-12 07:00:23+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(74,244,'Enchantment Horizon Treasure Cascade Chocolate','Carnival Piano Starlight Zephyr Carousel Tranquility Sleeping Apple Sunshine Cascade Twilight Whimsical Chocolate Radiance Adventure Jumping Adventure Bicycle Writing Elephant',4,'2004-09-29 02:20:08+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(20,268,'Enchantment Echo Jumping Eating Trampoline','Velvet Swimming Velvet Whisper Opulent Serendipity Butterfly Twilight Castle Lighthouse Secret Mountain Lighthouse Chocolate Enchantment Dragon Mystery Secret Carnival Zephyr',1,'2001-06-22 08:07:32+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(61,415,'Sleeping Rainbow Sleeping Carnival Treasure','Serendipity Radiance Lighthouse Serenade Piano Castle Reading Butterfly Opulent Thinking Singing Quicksilver Saffron Dragon Mystery Cascade Sunshine Saffron Whimsical Potion',1,'2008-07-06 18:42:37+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(23,5,'Euphoria Bamboo Harmony Potion Swimming','Horizon Whisper Singing Ocean Twilight Saffron Trampoline Secret Cascade Butterfly Rainbow Jumping Whisper Horizon Moonlight Mystery Velvet Castle Butterfly Enchantment',3,'2003-10-26 13:38:42+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(63,221,'Running Swimming Adventure Sunshine Apple','Dream Writing Starlight Treasure Rainbow Symphony Whisper Symphony Writing Elephant Harmony Opulent Horizon Radiance Serendipity Dream Adventure Galaxy Telescope Thinking',5,'2016-04-26 21:04:40+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(82,351,'Bamboo Apple Saffron Twilight Euphoria','Velvet Moonlight Zephyr Enchantment Moonlight Serendipity Rainbow Firefly Castle Bamboo Adventure Adventure Piano Writing Velvet Whisper Jumping Euphoria Treasure Radiance',2,'2014-08-20 15:15:01+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(22,201,'Elephant Tranquility Dancing Eating Sunshine','Horizon Enchantment Whisper Singing Mystery Mirage Chocolate Zephyr Reading Adventure Bamboo Velvet Velvet Whisper Serenade Serenade Running Echo Carnival Serendipity',4,'2011-12-08 01:56:47+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(31,218,'Swimming Thinking Dream Secret Chocolate','Bamboo Mystery Harmony Whimsical Velvet Bicycle Velvet Butterfly Eating Swimming Telescope Carnival Adventure Velvet Moonlight Potion Ocean Dragon Velvet Galaxy',5,'2020-09-08 08:43:27+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(27,293,'Twilight Singing Singing Treasure Radiance','Harmony Velvet Piano Eating Symphony Euphoria Castle Firefly Starlight Mirage Symphony Castle Cascade Starlight Mirage Harmony Mountain Radiance Euphoria Starlight',5,'2014-01-26 02:06:01+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(27,411,'Radiance Swimming Euphoria Ocean Quicksilver','Dancing Echo Opulent Mystery Thinking Opulent Apple Starlight Euphoria Potion Sleeping Swimming Carnival Bamboo Cascade Thinking Writing Potion Horizon Lighthouse',2,'2002-04-14 16:20:02+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(30,285,'Velvet Bicycle Eating Singing Zephyr','Cascade Apple Enchantment Sunshine Mirage Castle Mystery Running Serenade Butterfly Zephyr Tranquility Mystery Velvet Moonlight Bicycle Saffron Harmony Thinking Bamboo',5,'2018-08-23 13:03:34+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(25,473,'Firefly Piano Jumping Telescope Reading','Whimsical Echo Mystery Reading Adventure Dancing Tranquility Moonlight Castle Twilight Trampoline Running Enchantment Horizon Apple Bicycle Moonlight Chocolate Moonlight Quicksilver',4,'2006-06-12 12:32:20+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(69,109,'Singing Velvet Quicksilver Starlight Potion','Lighthouse Eating Zephyr Bicycle Tranquility Serenade Zephyr Enchantment Dream Velvet Mirage Starlight Radiance Dragon Serendipity Piano Elephant Aurora Potion Piano',5,'2019-03-18 09:19:55+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(79,439,'Sleeping Symphony Firefly Serenade Harmony','Reading Serenade Sleeping Trampoline Quicksilver Serenade Jumping Castle Serenade Moonlight Velvet Chocolate Mirage Sunshine Jumping Enchantment Secret Ocean Carousel Trampoline',3,'2019-04-20 17:42:23+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(42,166,'Dancing Rainbow Treasure Ocean Lighthouse','Potion Euphoria Piano Swimming Elephant Jumping Dancing Whimsical Starlight Quicksilver Tranquility Firefly Dancing Bamboo Running Telescope Ocean Singing Thinking Aurora',1,'2021-06-10 19:58:19+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(71,220,'Quicksilver Velvet Saffron Castle Potion','Sunshine Twilight Carousel Harmony Galaxy Thinking Dream Quicksilver Cascade Castle Dancing Whimsical Trampoline Sunshine Velvet Carousel Bamboo Ocean Bicycle Zephyr',1,'2008-11-22 14:25:47+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(35,83,'Thinking Enchantment Piano Elephant Saffron','Potion Secret Tranquility Bicycle Cascade Velvet Moonlight Radiance Swimming Sleeping Sleeping Jumping Treasure Cascade Velvet Serenade Rainbow Symphony Jumping Singing',4,'2002-02-19 16:27:33+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(32,339,'Whimsical Radiance Apple Secret Singing','Chocolate Velvet Running Writing Radiance Elephant Mystery Whimsical Bamboo Lighthouse Bicycle Galaxy Aurora Secret Tranquility Dream Carousel Castle Horizon Sunshine',1,'2000-05-01 04:08:49+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(45,387,'Carnival Harmony Velvet Elephant Dragon','Secret Opulent Sunshine Symphony Swimming Bamboo Secret Secret Twilight Symphony Rainbow Mountain Sunshine Mystery Serenade Enchantment Reading Ocean Mirage Carnival',1,'2016-04-24 14:46:14+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(36,344,'Mirage Echo Elephant Bicycle Dragon','Apple Rainbow Piano Saffron Thinking Sunshine Swimming Serenade Opulent Mystery Running Serenade Telescope Ocean Sleeping Harmony Dancing Mirage Apple Velvet',2,'2013-05-02 06:48:07+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(41,50,'Dancing Serenade Dream Whimsical Symphony','Trampoline Mountain Dream Dragon Firefly Apple Telescope Carousel Mountain Treasure Echo Thinking Chocolate Velvet Eating Serendipity Elephant Firefly Thinking Bamboo',5,'2010-09-05 08:26:08+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(36,9,'Mirage Telescope Quicksilver Quicksilver Moonlight','Dream Ocean Dragon Aurora Carnival Running Sleeping Starlight Mountain Castle Twilight Galaxy Dream Carousel Dream Starlight Lighthouse Elephant Jumping Starlight',2,'2022-07-10 23:43:44+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(26,486,'Whisper Lighthouse Thinking Enchantment Aurora','Telescope Sleeping Aurora Adventure Writing Echo Running Telescope Enchantment Mystery Quicksilver Rainbow Whimsical Carnival Treasure Ocean Bicycle Castle Echo Dream',3,'2007-11-23 18:02:39+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(54,300,'Moonlight Elephant Jumping Euphoria Symphony','Piano Adventure Treasure Mirage Telescope Chocolate Mirage Chocolate Twilight Zephyr Dream Firefly Bamboo Velvet Reading Whimsical Lighthouse Symphony Reading Starlight',1,'2000-06-24 11:41:54+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(22,404,'Carnival Elephant Writing Dream Moonlight','Zephyr Dream Radiance Horizon Secret Adventure Radiance Rainbow Opulent Piano Carousel Telescope Moonlight Dream Bamboo Chocolate Serendipity Swimming Harmony Secret',1,'2008-11-28 18:38:39+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(79,290,'Running Thinking Mystery Saffron Velvet','Dragon Treasure Firefly Galaxy Running Dancing Aurora Sunshine Singing Dragon Eating Whisper Mountain Telescope Twilight Moonlight Symphony Horizon Elephant Horizon',1,'2017-10-11 02:46:27+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(82,446,'Sunshine Sunshine Chocolate Euphoria Opulent','Tranquility Opulent Starlight Twilight Saffron Lighthouse Trampoline Moonlight Galaxy Tranquility Bamboo Moonlight Rainbow Writing Carousel Harmony Eating Galaxy Writing Rainbow',4,'2022-12-24 07:53:15+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(74,21,'Moonlight Quicksilver Zephyr Elephant Mystery','Elephant Adventure Apple Carnival Firefly Lighthouse Tranquility Aurora Jumping Bicycle Writing Piano Writing Velvet Twilight Dream Trampoline Lighthouse Euphoria Lighthouse',1,'2019-01-17 13:25:09+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(26,61,'Starlight Treasure Echo Serenade Moonlight','Elephant Quicksilver Castle Radiance Rainbow Serenade Echo Adventure Horizon Rainbow Rainbow Carnival Whisper Adventure Serenade Lighthouse Horizon Castle Potion Carnival',5,'2011-03-11 13:35:29+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(82,478,'Singing Twilight Potion Dragon Telescope','Saffron Mirage Adventure Reading Secret Bicycle Apple Chocolate Quicksilver Running Carousel Tranquility Thinking Moonlight Elephant Bamboo Piano Running Ocean Harmony',2,'2007-05-23 18:48:58+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(52,97,'Quicksilver Whimsical Dream Whisper Telescope','Saffron Adventure Symphony Sleeping Mountain Whisper Radiance Lighthouse Galaxy Echo Potion Twilight Echo Dream Jumping Writing Whisper Mountain Chocolate Aurora',3,'2012-12-13 23:50:14+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(50,174,'Apple Eating Bicycle Radiance Dragon','Apple Harmony Chocolate Dream Secret Harmony Telescope Reading Echo Quicksilver Swimming Quicksilver Elephant Radiance Telescope Telescope Harmony Secret Echo Opulent',4,'2015-07-29 09:11:26+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(62,326,'Horizon Chocolate Potion Aurora Velvet','Echo Sleeping Swimming Sleeping Radiance Trampoline Dream Thinking Dancing Quicksilver Whisper Bicycle Whimsical Euphoria Velvet Sleeping Reading Apple Sunshine Radiance',4,'2022-06-01 02:31:42+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(74,406,'Rainbow Mystery Galaxy Reading Writing','Reading Quicksilver Carnival Velvet Mountain Adventure Serendipity Sunshine Dancing Dragon Running Aurora Galaxy Mountain Euphoria Singing Bamboo Elephant Trampoline Twilight',3,'2019-10-10 17:16:40+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(55,143,'Carnival Twilight Chocolate Horizon Adventure','Dragon Bicycle Dragon Quicksilver Potion Quicksilver Aurora Mystery Moonlight Euphoria Treasure Bicycle Telescope Running Running Elephant Galaxy Treasure Bicycle Jumping',2,'2023-07-17 13:20:04+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,51,'Zephyr Symphony Secret Moonlight Mystery','Thinking Secret Twilight Thinking Firefly Secret Mountain Swimming Chocolate Firefly Twilight Adventure Bicycle Eating Ocean Singing Elephant Serendipity Carousel Velvet',3,'2000-01-25 22:34:45+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(77,225,'Butterfly Carousel Lighthouse Carousel Treasure','Trampoline Lighthouse Whisper Swimming Dragon Chocolate Radiance Galaxy Writing Adventure Chocolate Echo Piano Sleeping Piano Whisper Symphony Euphoria Singing Serenade',4,'2010-07-15 10:21:04+05');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(50,447,'Aurora Swimming Adventure Bamboo Whimsical','Lighthouse Trampoline Elephant Symphony Elephant Twilight Ocean Velvet Apple Thinking Singing Euphoria Sunshine Velvet Whisper Potion Starlight Sleeping Mirage Carnival',1,'2002-08-18 02:05:03+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(73,430,'Firefly Serenade Whimsical Jumping Carousel','Saffron Radiance Singing Telescope Piano Twilight Dancing Twilight Mountain Velvet Carnival Mystery Aurora Carousel Bamboo Mystery Cascade Potion Carnival Starlight',4,'2020-02-21 07:04:35+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(44,139,'Serenade Whisper Aurora Telescope Cascade','Thinking Dragon Apple Castle Echo Cascade Enchantment Carnival Butterfly Adventure Enchantment Telescope Dancing Writing Starlight Dream Firefly Potion Apple Mystery',3,'2016-02-19 13:35:46+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(23,19,'Swimming Eating Trampoline Echo Treasure','Bamboo Sunshine Swimming Trampoline Secret Adventure Writing Swimming Whimsical Dragon Serenade Dream Lighthouse Ocean Saffron Saffron Galaxy Opulent Piano Harmony',4,'2015-10-06 07:55:12+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(43,293,'Piano Enchantment Serendipity Dragon Piano','Dragon Aurora Castle Saffron Swimming Mirage Potion Mystery Tranquility Butterfly Mirage Whisper Apple Carousel Zephyr Galaxy Saffron Mirage Enchantment Aurora',4,'2004-10-10 13:16:16+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(98,56,'Serenade Velvet Trampoline Echo Running','Castle Opulent Tranquility Writing Horizon Jumping Elephant Ocean Bamboo Elephant Dream Writing Symphony Singing Piano Enchantment Serendipity Radiance Singing Symphony',4,'2011-08-26 17:55:38+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(16,338,'Thinking Rainbow Jumping Carnival Thinking','Aurora Zephyr Dream Twilight Tranquility Telescope Eating Writing Whisper Bamboo Enchantment Zephyr Mountain Serendipity Adventure Bamboo Cascade Swimming Running Carousel',3,'2000-01-19 03:10:19+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(13,325,'Mountain Lighthouse Telescope Secret Butterfly','Reading Trampoline Quicksilver Running Quicksilver Velvet Butterfly Serendipity Saffron Carousel Lighthouse Enchantment Euphoria Mystery Apple Chocolate Symphony Opulent Velvet Bamboo',3,'2000-01-21 20:37:21+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(6,204,'Dancing Thinking Ocean Telescope Potion','Twilight Velvet Trampoline Velvet Saffron Saffron Chocolate Harmony Harmony Mirage Opulent Dragon Bicycle Trampoline Euphoria Saffron Mirage Moonlight Trampoline Butterfly',1,'2002-11-09 00:30:32+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(43,442,'Lighthouse Thinking Firefly Horizon Dream','Zephyr Opulent Rainbow Whimsical Whimsical Swimming Carnival Apple Harmony Moonlight Dancing Starlight Bicycle Serenade Thinking Aurora Serendipity Trampoline Starlight Whisper',3,'2014-08-27 02:34:45+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(22,283,'Singing Eating Running Echo Tranquility','Starlight Starlight Swimming Echo Piano Dancing Whimsical Serenade Sunshine Apple Carnival Ocean Treasure Apple Thinking Serendipity Writing Velvet Aurora Piano',3,'2021-07-27 07:56:08+04');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(95,22,'Mountain Velvet Carnival Secret Mountain','Starlight Butterfly Opulent Dream Elephant Reading Castle Velvet Secret Mirage Singing Carousel Running Castle Tranquility Reading Radiance Carnival Serenade Potion',5,'2011-07-09 17:33:55+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(62,137,'Treasure Trampoline Adventure Harmony Apple','Euphoria Tranquility Running Eating Writing Carousel Symphony Serenade Velvet Firefly Bamboo Mystery Tranquility Dancing Secret Dream Bamboo Mountain Ocean Dancing',2,'2010-03-30 15:42:22+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(69,246,'Jumping Reading Cascade Starlight Telescope','Thinking Euphoria Treasure Butterfly Carousel Butterfly Zephyr Zephyr Secret Firefly Aurora Zephyr Cascade Whisper Carousel Carnival Zephyr Thinking Apple Swimming',4,'2018-02-04 13:46:23+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(46,63,'Chocolate Lighthouse Whisper Enchantment Piano','Starlight Quicksilver Saffron Harmony Telescope Symphony Saffron Velvet Echo Horizon Enchantment Moonlight Velvet Castle Serenade Secret Opulent Whimsical Symphony Symphony',1,'2006-10-25 12:38:54+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(95,72,'Rainbow Carousel Eating Bicycle Carousel','Velvet Euphoria Running Whimsical Velvet Aurora Aurora Bamboo Sleeping Dragon Secret Serenade Potion Singing Mystery Sunshine Euphoria Enchantment Adventure Euphoria',2,'2002-09-18 21:37:44+06');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(71,304,'Running Whimsical Writing Mountain Dragon','Sunshine Euphoria Mystery Telescope Telescope Piano Tranquility Mystery Carousel Dancing Opulent Chocolate Chocolate Mountain Rainbow Aurora Bicycle Potion Mountain Velvet',1,'2017-09-17 09:37:37+012');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(81,154,'Symphony Radiance Bamboo Butterfly Serenade','Chocolate Secret Opulent Adventure Sleeping Adventure Serendipity Saffron Dragon Mirage Mountain Swimming Saffron Castle Carnival Mystery Telescope Eating Sleeping Dancing',1,'2009-09-06 13:15:51+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(32,460,'Sleeping Mountain Twilight Whimsical Sleeping','Whimsical Treasure Harmony Dream Ocean Bamboo Mirage Aurora Galaxy Jumping Whisper Opulent Sleeping Piano Eating Rainbow Dream Bamboo Horizon Starlight',4,'2008-12-11 22:32:18+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(13,32,'Velvet Carnival Apple Thinking Serenade','Whisper Reading Harmony Echo Swimming Starlight Carousel Telescope Treasure Tranquility Treasure Mirage Radiance Ocean Treasure Starlight Mystery Euphoria Zephyr Moonlight',3,'2007-05-05 08:21:55+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(43,85,'Ocean Enchantment Mountain Carousel Carousel','Rainbow Elephant Apple Reading Ocean Writing Sleeping Running Enchantment Radiance Zephyr Lighthouse Dragon Reading Moonlight Piano Potion Enchantment Secret Serendipity',4,'2019-03-23 22:58:03+00');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(74,458,'Dancing Whisper Mirage Elephant Adventure','Treasure Writing Serendipity Echo Aurora Radiance Chocolate Saffron Enchantment Velvet Mountain Radiance Starlight Writing Mirage Cascade Writing Adventure Eating Twilight',1,'2018-04-06 12:14:44+09');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(69,367,'Echo Apple Trampoline Galaxy Zephyr','Mirage Singing Harmony Echo Adventure Velvet Thinking Saffron Tranquility Bamboo Jumping Treasure Twilight Elephant Mountain Velvet Whimsical Harmony Tranquility Telescope',3,'2004-03-07 02:43:59+02');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(70,221,'Galaxy Adventure Jumping Rainbow Enchantment','Starlight Moonlight Quicksilver Dancing Elephant Eating Euphoria Carousel Aurora Elephant Secret Echo Chocolate Singing Saffron Chocolate Carnival Butterfly Writing Mountain',4,'2011-02-24 07:56:56+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(91,401,'Apple Castle Galaxy Whimsical Zephyr','Chocolate Secret Thinking Enchantment Sleeping Enchantment Swimming Sleeping Serendipity Whisper Adventure Whisper Velvet Moonlight Lighthouse Eating Mirage Treasure Harmony Opulent',5,'2018-07-07 08:45:41+010');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(41,178,'Mystery Bicycle Serenade Jumping Whimsical','Trampoline Carousel Mystery Zephyr Cascade Reading Trampoline Telescope Lighthouse Piano Whisper Chocolate Singing Sunshine Saffron Telescope Horizon Ocean Ocean Starlight',4,'2012-03-14 20:23:48+08');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(98,421,'Telescope Radiance Zephyr Dream Dream','Dream Bamboo Singing Elephant Serenade Velvet Castle Quicksilver Mountain Euphoria Thinking Treasure Piano Whimsical Moonlight Enchantment Secret Firefly Twilight Eating',2,'2022-05-04 10:56:56+011');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(72,163,'Singing Ocean Trampoline Rainbow Swimming','Velvet Treasure Serenade Bicycle Dream Elephant Harmony Serendipity Enchantment Chocolate Tranquility Dancing Enchantment Carnival Telescope Trampoline Whimsical Firefly Enchantment Velvet',1,'2017-09-14 07:19:03+07');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(70,61,'Dragon Sunshine Firefly Elephant Cascade','Quicksilver Firefly Rainbow Telescope Galaxy Zephyr Jumping Serenade Apple Enchantment Enchantment Mystery Horizon Castle Zephyr Dream Adventure Rainbow Trampoline Bamboo',4,'2011-04-01 08:38:00+01');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(35,406,'Elephant Horizon Cascade Whisper Radiance','Tranquility Tranquility Horizon Velvet Apple Dream Horizon Twilight Carousel Tranquility Castle Horizon Sunshine Writing Velvet Carnival Radiance Carnival Cascade Swimming',2,'2017-02-08 14:30:15+03');
INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES(79,308,'Galaxy Castle Carnival Zephyr Running','Lighthouse Jumping Butterfly Cascade Eating Running Saffron Serendipity Velvet Serendipity Swimming Whimsical Thinking Opulent Tranquility Sleeping Trampoline Swimming Moonlight Jumping',2,'2012-06-03 16:00:38+04');

INSERT INTO review_report(review_id,motive,date) VALUES(40,'Moonlight Apple Castle Potion Saffron Starlight Harmony Opulent Bamboo Castle Swimming Eating Whimsical Treasure Opulent Galaxy Firefly Butterfly Swimming Euphoria','2017-01-10 11:21:38+010');
INSERT INTO review_report(review_id,motive,date) VALUES(24,'Euphoria Moonlight Mirage Bamboo Carnival Velvet Castle Twilight Eating Dream Dream Whisper Rainbow Horizon Opulent Treasure Telescope Treasure Potion Horizon','2010-04-29 17:45:05+05');
INSERT INTO review_report(review_id,motive,date) VALUES(112,'Writing Dancing Apple Mountain Whisper Serenade Velvet Sunshine Galaxy Sunshine Potion Trampoline Eating Dancing Lighthouse Carnival Rainbow Thinking Telescope Quicksilver','2009-03-21 18:55:17+09');
INSERT INTO review_report(review_id,motive,date) VALUES(129,'Opulent Reading Echo Dancing Mountain Rainbow Zephyr Mirage Chocolate Carnival Chocolate Reading Carousel Sleeping Tranquility Whimsical Sunshine Rainbow Piano Bicycle','2010-04-12 19:32:23+06');
INSERT INTO review_report(review_id,motive,date) VALUES(110,'Thinking Potion Carousel Symphony Symphony Piano Twilight Singing Carnival Twilight Whimsical Dragon Reading Quicksilver Tranquility Chocolate Zephyr Euphoria Mountain Cascade','2005-06-14 17:52:34+01');
INSERT INTO review_report(review_id,motive,date) VALUES(47,'Whisper Enchantment Twilight Reading Potion Telescope Euphoria Echo Piano Butterfly Whisper Secret Ocean Opulent Thinking Eating Secret Eating Lighthouse Quicksilver','2020-05-24 22:21:15+010');
INSERT INTO review_report(review_id,motive,date) VALUES(119,'Swimming Dancing Quicksilver Radiance Piano Mountain Symphony Castle Rainbow Saffron Serendipity Lighthouse Mirage Serenade Piano Piano Carnival Castle Sleeping Dragon','2020-08-30 02:49:47+08');
INSERT INTO review_report(review_id,motive,date) VALUES(84,'Radiance Firefly Potion Carnival Reading Carousel Bamboo Mountain Jumping Trampoline Swimming Carousel Harmony Starlight Echo Enchantment Elephant Opulent Potion Swimming','2006-02-01 23:28:35+06');
INSERT INTO review_report(review_id,motive,date) VALUES(136,'Elephant Serendipity Bicycle Mirage Reading Velvet Reading Butterfly Swimming Ocean Aurora Euphoria Lighthouse Firefly Singing Dream Singing Singing Adventure Mountain','2009-08-31 12:08:53+02');
INSERT INTO review_report(review_id,motive,date) VALUES(104,'Carousel Bicycle Swimming Singing Mystery Thinking Lighthouse Singing Chocolate Butterfly Writing Tranquility Twilight Whisper Mystery Potion Butterfly Moonlight Moonlight Reading','2004-08-06 20:24:46+05');
INSERT INTO review_report(review_id,motive,date) VALUES(49,'Mountain Horizon Jumping Writing Trampoline Aurora Mountain Sunshine Bicycle Running Mystery Horizon Secret Whimsical Sleeping Cascade Bicycle Velvet Lighthouse Carnival','2002-06-27 16:18:08+04');
INSERT INTO review_report(review_id,motive,date) VALUES(3,'Jumping Dancing Horizon Ocean Galaxy Mountain Carousel Reading Tranquility Whisper Mystery Potion Quicksilver Galaxy Mountain Ocean Zephyr Sleeping Saffron Velvet','2004-08-04 18:03:42+010');
INSERT INTO review_report(review_id,motive,date) VALUES(45,'Moonlight Eating Eating Mountain Whisper Serenade Sleeping Ocean Dragon Secret Quicksilver Apple Lighthouse Swimming Writing Apple Thinking Trampoline Enchantment Velvet','2015-12-09 10:48:23+01');
INSERT INTO review_report(review_id,motive,date) VALUES(30,'Firefly Writing Harmony Jumping Dream Butterfly Castle Enchantment Saffron Thinking Eating Velvet Symphony Butterfly Ocean Whimsical Carnival Whisper Trampoline Swimming','2022-02-06 16:18:12+011');
INSERT INTO review_report(review_id,motive,date) VALUES(7,'Sunshine Velvet Dream Cascade Serenade Swimming Twilight Galaxy Elephant Adventure Piano Opulent Dream Eating Dancing Moonlight Apple Lighthouse Serenade Echo','2003-06-24 12:20:24+09');
INSERT INTO review_report(review_id,motive,date) VALUES(135,'Sunshine Jumping Echo Reading Starlight Dragon Rainbow Mirage Symphony Writing Dragon Aurora Serenade Running Rainbow Quicksilver Moonlight Sleeping Carousel Eating','2015-04-15 02:20:59+07');
INSERT INTO review_report(review_id,motive,date) VALUES(1,'Butterfly Horizon Moonlight Apple Whimsical Sunshine Running Dancing Echo Bamboo Sunshine Potion Apple Eating Carnival Tranquility Dragon Firefly Mirage Secret','2015-12-10 14:34:01+010');
INSERT INTO review_report(review_id,motive,date) VALUES(62,'Symphony Twilight Zephyr Serendipity Enchantment Harmony Galaxy Singing Harmony Apple Adventure Telescope Quicksilver Velvet Enchantment Moonlight Mystery Potion Quicksilver Sunshine','2002-05-23 17:26:36+04');
INSERT INTO review_report(review_id,motive,date) VALUES(26,'Aurora Dragon Whimsical Lighthouse Velvet Opulent Lighthouse Bicycle Euphoria Bamboo Whimsical Horizon Jumping Cascade Sleeping Symphony Velvet Reading Aurora Dragon','2023-02-08 13:14:40+03');
INSERT INTO review_report(review_id,motive,date) VALUES(185,'Whimsical Eating Tranquility Butterfly Chocolate Mountain Saffron Singing Trampoline Thinking Thinking Rainbow Euphoria Moonlight Mystery Mystery Sleeping Aurora Lighthouse Running','2004-09-08 19:24:52+00');
