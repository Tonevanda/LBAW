---- BEGIN INSERTING AUTHENTICATED USER TRANSACTION (TRAN01) REQUIRES AN INSERT ON TABLE currency ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

DO $BODY$
DECLARE
    user_name text := 'test_dummy_name';
    user_password text := 'test_dummy_password';
    user_email text := 'test_dummy_email';
    user_address text := 'test_dummy_address';
    check_email text := NULL;

BEGIN
    EXECUTE 'SELECT email FROM users WHERE email = $1' INTO check_email USING user_email;
    IF check_email IS NULL THEN 
        EXECUTE 'INSERT INTO users (name, password, email, profile_picture) 
        VALUES ($1, $2, $3, DEFAULT)' USING user_name, user_password, user_email;

        EXECUTE 'INSERT INTO authenticated (user_id, address, isBlocked) 
        VALUES ((SELECT id FROM users WHERE email = $1), $2, DEFAULT)' USING user_email, user_address;

    END IF;

EXCEPTION
    WHEN others THEN
        ROLLBACK;

END;
$BODY$
LANGUAGE plpgsql;


END TRANSACTION;

---- END INSERTING AUTHENTICATED USER TRANSACTION   ------

---- BEGIN PRODUCT SEARCH AND DISPLAY TRANSACTION (TRAN02) REQURES AN INSERT ON TABLE category AND AN INSERT ON TABLE product AND AN INSERT ON TABLE product_category (TRAN16)------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

DO $BODY$
DECLARE
        filter_query TEXT := '';
        price_filter INTEGER := 28;
        category_filter TEXT := NULL;
        name_filter TEXT := 'bad star game';
        name_filter_array TEXT[];
        i INTEGER := 1;
        query_record record;
BEGIN
        IF price_filter IS NOT NULL THEN
            filter_query := filter_query || ' AND price <= ' || price_filter;
        END IF;
        IF category_filter IS NOT NULL THEN
            filter_query := filter_query || ' AND category_type = ' 
            || quote_literal(category_filter);
        END IF;
        IF name_filter IS NOT NULL THEN 
            name_filter_array := regexp_split_to_array(name_filter, '\s+');
            name_filter_array := array_remove(name_filter_array, '');
            name_filter := '';
            WHILE i <= array_length(name_filter_array, 1) LOOP
                IF name_filter = '' THEN
                    name_filter := name_filter_array[i];
                ELSE 
                    name_filter := name_filter || ' & ' || name_filter_array[i];
                END IF;
                IF i = array_length(name_filter_array, 1) THEN
                        name_filter := name_filter || ':*';
                        name_filter := filter_query || ' AND tsvectors @@ to_tsquery(' 
                        || quote_literal('english') || ', ' || quote_literal(name_filter) || 
                        ') ORDER BY ts_rank(tsvectors, to_tsquery(' || quote_literal('english') || ', ' || quote_literal(name_filter) || ')) DESC';
                        RAISE NOTICE 'QUERY: %', name_filter;
                        EXECUTE 'SELECT name, id, price, discount, stock, author, editor, image, category_type
                            FROM product 
                            FULL JOIN product_category ON product_category.product_id = product.id 
                            WHERE 1=1' || name_filter
                            INTO query_record;

                        RAISE NOTICE 'QUERY: %', query_record.name;
                            
                        IF query_record.name IS NOT NULL THEN
                            RAISE NOTICE 'QUERY: %', query_record.name;
                            EXIT;
                        ELSE
                            name_filter_array := array_remove(name_filter_array, name_filter_array[i]);
                            i := 0;
                            name_filter := '';
                        END IF;
                END IF;
                i := i+1;
            END LOOP; 
        ELSE
            EXECUTE 'SELECT name, id, price, discount, stock, author, editor, image, category_type
                            FROM product 
                            LEFT JOIN product_category ON product_category.product_id = product.id 
                            WHERE 1=1' || filter_query
                            INTO query_record;
            RAISE NOTICE 'QUERY: %', query_record.name;
        END IF;
END;
$BODY$
LANGUAGE plpgsql;
END TRANSACTION;

---- END PRODUCT SEARCH AND DISPLAY TRANSACTION   ------

---- BEGIN DELETE AUTHENTICATED USER (TRAN03) REQUIRES A CURRENCY AND AN AUTHENTICATED USER (TRAN01)------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    deleted_user_email TEXT := 'test_dummy_email';
    deleted_user_id INTEGER;
BEGIN
    EXECUTE 'SELECT user_id FROM authenticated INNER JOIN users ON users.id = authenticated.user_id WHERE email = $1' INTO deleted_user_id USING deleted_user_email;

    IF deleted_user_id IS NOT NULL THEN
        EXECUTE 'DELETE FROM authenticated
         WHERE user_id = $1' USING deleted_user_id;

    ELSE
        
        ROLLBACK;
    END IF;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END INSERTING ADMIN TRANSACTION   ------

---- BEGIN EDITING AUTHENTICATED USER PROFILE TRANSACTION (TRAN04) REQUIRES A CURRENCY AND AN AUTHENTICATED USER (TRAN01)------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

DO $BODY$
DECLARE
    user_name text := 'test_dummy_new_name';
    user_password text := 'test_dummy_new_password';
    user_email text := 'test_dummy_email';
    user_address text := 'test_dummy_new_address';
    user_profile_picture text := 'df_user_img.png';
    real_email text := 'test_dummy_email';
    userID INTEGER := NULL;

BEGIN
    EXECUTE 'SELECT user_id FROM authenticated INNER JOIN users ON user_id = id WHERE email = $1' INTO userID USING real_email;

    IF userID IS NOT NULL THEN

        IF NOT EXISTS (SELECT 1 FROM users WHERE email = user_email AND id != userID) THEN
            UPDATE users
            SET name = user_name, password = user_password, email = user_email, profile_picture = user_profile_picture
            WHERE id = userID;
            UPDATE authenticated
            SET address = user_address
            WHERE user_id = userID;
        END IF;
    END IF;
    

EXCEPTION
    WHEN others THEN
        ROLLBACK;

END;
$BODY$
LANGUAGE plpgsql;


END TRANSACTION;

---- END EDITING AUTHENTICATED USER PROFILE TRANSACTION   ------

---- BEGIN INSERTING ADMIN TRANSACTION (TRAN05) ------
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

DO $BODY$
DECLARE
    admin_name text := 'test_admin_dummy_name';
    admin_password text := 'test_admin_dummy_password';
    admin_email text := 'test_admin_dummy_email';
    admin_adress text := 'test_admin_dummy_adress';

BEGIN

    EXECUTE 'INSERT INTO users (name, password, email, profile_picture) 
    VALUES ($1, $2, $3, DEFAULT)' USING admin_name, admin_password, admin_email;

    EXECUTE 'INSERT INTO admin (admin_id) 
    VALUES ((SELECT id FROM users WHERE email = $1))' USING admin_email;

EXCEPTION
    WHEN others THEN
        ROLLBACK;

END;
$BODY$
LANGUAGE plpgsql;


END TRANSACTION;

---- END INSERTING ADMIN TRANSACTION   ------




---- BEGIN ADD TO SHOPPING CART TRANSACTION (TRAN06) REQUIRES A CURRENCY AND AN AUTHENTICATED USER (TRAN01) AND A PRODUCT ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    user_email TEXT := 'test_dummy_email';
    user_id INTEGER;
    product_id INTEGER := 1;
    query_record record;
BEGIN

    EXECUTE 'SELECT id FROM users WHERE email = $1' INTO user_id USING user_email;
    
    IF user_id IS NOT NULL THEN
        EXECUTE 'INSERT INTO shopping_cart (user_id, product_id) VALUES ($1, $2)' USING user_id, product_id;
    END IF;
EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END ADD TO SHOPPING CART TRANSACTION   ------


---- BEGIN ADD TO WISHLIST TRANSACTION (TRAN07) REQUIRES A CURRENCY AND AN AUTHENTICATED USER (TRAN01) AND A PRODUCT ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    user_email TEXT := 'test_dummy_email';
    user_id INTEGER;
    product_id INTEGER := 2;
    query_record record;
BEGIN

    EXECUTE 'SELECT id FROM users WHERE email = $1' INTO user_id USING user_email;
    
    IF user_id IS NOT NULL THEN
        EXECUTE 'INSERT INTO wishlist (user_id, product_id) VALUES ($1, $2)' USING user_id, product_id;
    END IF;
EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END ADD TO WISHLIST TRANSACTION   ------

---- BEGIN PURCHASE TRANSACTION (TRAN08) REQUIRES A CURRENCY AND AN AUTHENTICATED USER (TRAN01) AND A PRODUCT A PAYMENT ------
---- AND A STAGE AND PRODUCTS ADDED TO THE SHOOPING CART (TRAN06)  ------




BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
DO $BODY$
DECLARE
    user_email TEXT := 'test_dummy_email';
    user_id INTEGER;
    price INTEGER := 0;
    quantity INTEGER := 0;
    payment_type TEXT := 'paypal';
    destination TEXT := 'test_dummy_destination';
    time_delay INTEGER := 0;
    product_id INTEGER;
    id INTEGER;
    query_record record;
    random_date_offset INTERVAL;
BEGIN

    EXECUTE 'SELECT user_id FROM authenticated INNER JOIN users ON users.id = authenticated.user_id WHERE email = $1' INTO user_id USING user_email;

    IF user_id IS NOT NULL THEN

        FOR id IN EXECUTE 'SELECT id FROM shopping_cart WHERE user_id = $1' USING user_id

        LOOP
            EXECUTE 'SELECT product_id FROM shopping_cart WHERE id = $1' INTO product_id USING id;
            EXECUTE 'SELECT price, discount, stock, orderStatus FROM product WHERE id = $1' INTO query_record USING product_id;
            IF query_record.stock > 0 THEN
                price := price + query_record.price - query_record.discount;
                quantity := quantity + 1;
                time_delay := time_delay + query_record.orderStatus*24;
                UPDATE product
                SET stock = stock-1
                WHERE product.id = product_id;
            ELSE
                EXECUTE 'DELETE FROM shopping_cart WHERE id = $1' USING id;
            END IF;
        END LOOP;
        IF quantity != 0 THEN
            random_date_offset := (floor(random() * 100 + time_delay/quantity) || ' hours')::INTERVAL;
            EXECUTE 'INSERT INTO purchase (user_id, price, quantity, payment_type, destination, stage_state, isTracked, orderedAt, orderArrivedAt) VALUES ($1, $2, $3, $4, $5, $6, DEFAULT, $7, $8)' 
            USING user_id, price, quantity, payment_type, destination, 'payment', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + random_date_offset;
        END IF;
    END IF;
EXCEPTION
    WHEN others THEN
        ROLLBACK;

    
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;


---- END PURCHASE TRANSACTION  ------

---- BEGIN CANCEL ORDER TRANSACTION (TRAN09) REQUIRES A PRODUCT AND A PURCHASE (TRAN08) AND AN AUTHENTICATED USER (TRAN01) ------
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
DO $BODY$
DECLARE
    purchase_id INTEGER := 1;
    arrived_date TIMESTAMP WITH TIME ZONE := NULL;
BEGIN
    EXECUTE 'SELECT orderArrivedAt FROM purchase WHERE id = $1' INTO arrived_date USING purchase_id;
    
    IF arrived_date IS NOT NULL AND arrived_date <= CURRENT_TIMESTAMP THEN
        RAISE NOTICE 'QUERY: %', purchase_id;
        EXECUTE 'DELETE FROM purchase WHERE id = $1' USING purchase_id;
        RAISE NOTICE 'QUERY: %', purchase_id;
    END IF;

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;
---- END CANCEL ORDER TRANSACTION  ------

---- BEGIN VIEW PRODUCT DETAILS TRANSACTION (TRAN10) REQUIRES A PRODUCT ------
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED READ ONLY;
DO $BODY$
DECLARE
    product_id INTEGER := 1;
BEGIN


    EXECUTE 'SELECT * FROM product WHERE id = $1' USING product_id

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;
---- END VIEW PRODUCT DETAILS TRANSACTION  ------

---- BEGIN INSERT REVIEW TRANSACTION (TRAN11) REQUIRES A PRODUCT AND AN AUTHENTICATED USER (TRAN01) ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    productID INTEGER := 1;
    user_email TEXT := 'test_dummy_email';
    userID INTEGER;
    isBlocked BOOLEAN;
    title TEXT := 'test_dummy_title';
    description TEXT := 'test_dummy_description';
    rating INTEGER := 4;
BEGIN

    EXECUTE 'SELECT user_id, isBlocked FROM authenticated INNER JOIN users ON users.id = authenticated.user_id WHERE email = $1' INTO userID, isBlocked USING user_email;

    IF userID IS NOT NULL AND isBlocked = FALSE THEN
        IF NOT EXISTS (SELECT 1 FROM review WHERE user_id = userID AND product_id = productID) THEN
            EXECUTE 'INSERT INTO review (user_id, product_id, title, description, rating, date) VALUES ($1, $2, $3, $4, $5, $6)' USING userID, productID, title, description, rating, CURRENT_TIMESTAMP;
        END IF;
    END IF;

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END INSERT REVIEW TRANSACTION  ------

---- BEGIN DELETE REVIEW TRANSACTION (TRAN12) REQUIRES A REVIEW (TRAN11) ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    review_id INTEGER := 1;
BEGIN
    IF EXISTS (SELECT 1 FROM review WHERE id = review_id) THEN
        EXECUTE 'DELETE FROM review WHERE id = $1' USING review_id;
    END IF;

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END DELETE REVIEW TRANSACTION  ------

---- BEGIN BLOCK/UNBLOCK USER TRANSACTION (TRAN13) REQUIRES AN AUTHENTICATED USER (TRAN01) ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DO $BODY$
DECLARE
    user_email TEXT := 'test_dummy_email';
    userID INTEGER;
    change_value BOOLEAN := FALSE;
BEGIN
    EXECUTE 'SELECT user_id FROM authenticated INNER JOIN users ON users.id = authenticated.user_id WHERE email = $1' INTO userID USING user_email;
    IF userID IS NOT NULL THEN
        UPDATE authenticated
        SET isBlocked = change_value
        WHERE user_id = userID;
    END IF;

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END BLOCK/UNBLOCK USER TRANSACTION  ------

---- BEGIN EDIT PRODUCT INFORMATION TRANSACTION (TRAN14) REQUIRES A PRODUCT  ------

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
DO $BODY$
DECLARE
    product_id INTEGER := 1;
    product_name TEXT := 'Game of Thrones';
    product_synopsis TEXT := 'test_dummy_product_synopsis';
    product_author TEXT := 'text_dummy_product_author';
    product_editor TEXT := 'test_dummy_product_editor';
    product_stock INTEGER := 4;
    product_discount INTEGER := 6;
    product_language TEXT := 'english';
    product_image TEXT := 'game_of_thrones.png';
    product_orderStatus INTEGER := 20;
BEGIN
    IF EXISTS (SELECT 1 FROM product WHERE id = product_id) THEN
        UPDATE product
        SET name = product_name, synopsis = product_synopsis, author = product_author, editor = product_editor, 
        stock = product_stock, discount = product_discount, language = product_language, image = product_image, orderStatus = product_orderStatus
        WHERE id = product_id;
    END IF;
    

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END EDIT PRODUCT INFORMATION TRANSACTION  ------

---- BEGIN ADD PRODUCT CATEGORY TRANSACTION (TRAN15) REQUIRES A CATEGORY AND A PRODUCT ------
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
DO $BODY$
DECLARE
    categoryType TEXT := 'Romance';
    product_id INTEGER := 1;
BEGIN
    IF EXISTS (SELECT 1 FROM product WHERE id = product_id) THEN
        IF EXISTS (SELECT 1 FROM category WHERE category_type = categoryType) THEN
            EXECUTE 'INSERT INTO product_category (product_id, category_type) VALUES ($1, $2)' USING product_id, categoryType;
        END IF;
    END IF;
    

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END ADD PRODUCT CATEGORY TRANSACTION  ------

---- BEGIN REMOVE PRODUCT CATEGORY TRANSACTION (TRAN17) REQUIRES A product_category (TRAN15) ------
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
DO $BODY$
DECLARE
    categoryType TEXT := 'Romance';
    productID INTEGER := 1;
BEGIN
    IF EXISTS (SELECT 1 FROM product_category WHERE product_id = productID AND category_type = categoryType) THEN
        EXECUTE 'DELETE FROM product_category WHERE product_id = $1 AND category_type = $2' USING productID, categoryType;
    END IF;
    

EXCEPTION
    WHEN others THEN
        ROLLBACK;
END;
$BODY$
LANGUAGE plpgsql;

END TRANSACTION;

---- END REMOVE PRODUCT CATEGORY TRANSACTION  ------
