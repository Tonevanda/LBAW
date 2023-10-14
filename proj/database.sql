PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS admin;
DROP TABLE IF EXISTS authenticated;
DROP TABLE IF EXISTS currency;
DROP TABLE IF EXISTS wallet;
DROP TABLE IF EXISTS unblock_appeal;
DROP TABLE IF EXISTS notification;
DROP TABLE IF EXISTS authenticated_notification;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS shopping_cart;
DROP TABLE IF EXISTS wishlist;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS stage;
DROP TABLE IF EXISTS purchase_history;
DROP TABLE IF EXISTS statistic;
DROP TABLE IF EXISTS product_statistic;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS product_category;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS review_report;

CREATE TYPE notification_type AS ENUM ('PaymentNotification', 'InStockNotification', 'PurchaseInfoNotification', 'PriceChangeNotification');

CREATE TYPE currency_type AS ENUM ('EuroCurrency', 'PoundCurrency', 'DollarCurrency', 'RupeeCurrency');

CREATE TYPE payment_type AS ENUM ('StoreMoneyPayment', 'In stock', 'Purchase Info', 'Price change');

CREATE TYPE stage_state AS ENUM ('PurchasedStage', 'In stock', 'Purchase Info', 'ArrivedStage');

CREATE TYPE category_type AS ENUM ('FictionCategory', 'Non-FictionCategory', 'MysteryCategory', 'RomanceCategory' , 'ComicsCategory' , 'HorrorCategory');

CREATE TABLE notification (
    TYPE notification_type PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE currency (
    TYPE currency_type PRIMARY KEY
);

CREATE TABLE payment (
    TYPE payment_type PRIMARY KEY
);

CREATE TABLE stage (
    TYPE stage_state PRIMARY KEY
);

CREATE TABLE statistic (
    TYPE statistic_type PRIMARY KEY,
    result INTEGER NOT NULL
);

CREATE TABLE category (
    TYPE category_type PRIMARY KEY
);

CREATE TABLE user (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    email TEXT NOT NULL CONSTRAINT email_ck UNIQUE,
    profile_picture TEXT
);

CREATE TABLE admin (
    admin_id INTEGER PRIMARY KEY REFERENCES user (id) ON UPDATE CASCADE
);

CREATE TABLE authenticated (
    user_id INTEGER PRIMARY KEY REFERENCES user (id) ON UPDATE CASCADE,
    adress TEXT,
    isBlocked BOOLEAN DEFAULT FALSE
);


CREATE TABLE wallet (
    id INTEGER PRIMARY KEY REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    money INTEGER DEFAULT 0,
    TYPE currency_type NOT NULL REFERENCES currency (currency_type) ON UPDATE CASCADE,
    transaction_date TIMESTAMP WITH TIME ZONE
);


CREATE TABLE unblock_appeal (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);


CREATE TABLE authenticated_notification (
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    TYPE notification_type REFERENCES notification (notification_type) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, notification_type)
);

CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    synopsis TEXT NOT NULL,
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price >= 0),
    discount INTEGER CONSTRAINT discount_ck CHECK (discount < price),
    stock INTEGER NOT NULL CONSTRAINT stock_ck CHECK (stock >= 0),
    author TEXT DEFAULT 'anonymous' NOT NULL,
    editor TEXT DEFAULT 'self published' NOT NULL,
    language NOT NULL,
    image,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE shopping_cart (
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE wishlist (
    user_id INTEGER REFERENCES authenticated (user_id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE purchase (
    id SERIAL PRIMARY KEY,
    price INTEGER NOT NULL,
    quantity NOT NULL CONSTRAINT quantity_ck CHECK (quantity > 0),
    TYPE payment_type NOT NULL,
    destination TEXT NOT NULL,
    TYPE stage_state NOT NULL,
    orderedAt TIMESTAMP WITH TIME ZONE NOT NULL,
    orderArrivedAt TIMESTAMP WITH TIME ZONE CONSTRAINT order_ck CHECK (orderArrivedAt > orderedAt) 
);


CREATE TABLE purchase_history (
    purchase_id INTEGER REFERENCES purchase (id) ON UPDATE CASCADE,
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    quantity INTEGER NOT NULL CONSTRAINT quantity_ck CHECK (quantity > 0),
    price INTEGER NOT NULL CONSTRAINT price_ck CHECK (price > 0),
    PRIMARY KEY (purchase_id, product_id)
);


CREATE TABLE product_statistic (
    product_id INTEGER REFERENCES product (id) ON UPDATE CASCADE,
    TYPE statistic_type REFERENCES statistic (statistic_type) ON UPDATE CASCADE
    PRIMARY KEY (product_id, statistic_type)
);


CREATE TABLE product_category (
    product_id INTEGER REFERENCES product (id),
    TYPE category_type REFERENCES category (category_type),
    PRIMARY KEY (product_id, category_type)
);

CREATE TABLE review (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES authenticated (user_id),
    title TEXT NOT NULL,
    description TEXT,
    rating INTEGER CONSTRAINT rating_ck (((0 <=rating) OR (rating >= 5))),
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE review_report (
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES review (id),
    motive TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

