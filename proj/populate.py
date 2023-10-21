import secrets
import string
import random
import time
from datetime import datetime, timedelta

# Abre o ficheiro populate.sql com write perms, elimina o conteúdo que já estiver dentro

start_time = time.time()

file = open('proj/populate.sql',"w")

# Notification 
notification_types = ['payment_notification', 'instock_notification','purchaseinfo_notification','pricechange_notification']
notification_descriptions = [['Your payment has been successful','Your payment has failed, please try again'], 'An item on your wishlist is currently in stock', "Thank you for purchasing at our store, this is your purchase's information:", "An item on your wishlist has had its price changed"]

file.write(f'INSERT INTO notification VALUES("{notification_types[0]}","{notification_descriptions[0][0]}");\n')
file.write(f'INSERT INTO notification VALUES("{notification_types[0]}","{notification_descriptions[0][1]}");\n')
file.write(f'INSERT INTO notification VALUES("{notification_types[1]}","{notification_descriptions[1]}");\n')
file.write(f'INSERT INTO notification VALUES("{notification_types[2]}","{notification_descriptions[2]}");\n')
file.write(f'INSERT INTO notification VALUES("{notification_types[3]}","{notification_descriptions[3]}");\n')

file.write("\n")

# Currency
currency_types = ['euro', 'pound','dollar','rupee','yen']

for currency in currency_types:
    file.write(f'INSERT INTO currency VALUES("{currency}");\n')    

file.write("\n")

# Payment
payment_types = ['paypal','credit/debit card','store money']

for payment in payment_types:
    file.write(f'INSERT INTO payment VALUES("{payment}");\n')    

file.write("\n")

# Stage
stages = ['payment','order','transportation','delivered']

for stage in stages:
    file.write(f'INSERT INTO stage VALUES("{stage}");\n') 

file.write("\n")

# Statistic
statistic_types = ['sales','revenue','AOV','returnrate']

for statistic in statistic_types:
    file.write(f'INSERT INTO statistic VALUES("{statistic}");\n') 

file.write("\n")

# Category
categories = ['fiction','non-fiction','mystery','romance','comics','horror']

for category in categories:
    file.write(f'INSERT INTO category VALUES("{category}");\n') 

file.write("\n")

# Users
users_name = [

'Olivia',	'Noah',
'Emma',	'Liam',
'Amelia',	'Oliver',
'Sophia',	'Mateo',
'Charlotte',	'Elijah',
'Ava',	'Lucas',
'Isabella',	'Levi',
'Mia',	'Leo',
'Luna',	'Ezra',
'Evelyn',	'Luca',
'Gianna',	'Asher',
'Lily',	'James',
'Aria',	'Ethan',
'Ellie',	'Sebastian',
'Aurora',	'Henry',
'Harper',	'Muhammad',
'Mila',	'Hudson',
'Sofia',	'Maverick',
'Camila',	'Kai',
'Eliana',	'Benjamin',
'Nova',	'Jackson',
'Layla',	'Theo',
'Ella',	'Daniel',
'Hazel',	'Aiden',
'Violet',	'Elias',
'Willow',	'Michael',
'Chloe',	'Mason',
'Ivy',	'Jack',
'Scarlett',	'Grayson',
'Penelope',	'Gabriel',
'Eleanor',	'Josiah',
'Elena',	'Alexander',
'Avery',	'Luke',
'Emily',	'Julian',
'Abigail',	'David',
'Nora',	'Jayden',
'Delilah',	'Carter',
'Maya',	'Logan',
'Isla',	'Theodore',
'Elizabeth',	'Owen',
'Naomi',	'Wyatt',
'Grace',	'Samuel',
'Zoey',	'Ezekiel',
'Riley',	'Waylon',
'Zoe',	'William',
'Emilia',	'Miles',
'Athena',	'Isaiah',
'Paisley',	'Matthew',
'Leilani',	'Santiago',
'Madison',	'Jacob'
]

def generate_random_username():
    # Pick random names from list
    firstName = users_name[random.randrange(len(users_name))]
    secondName = users_name[random.randrange(len(users_name))]
    return firstName + ' ' + secondName

def generate_random_password(length=12):
    # Define characters to include in the password
    allowed_chars = string.ascii_letters + string.digits + string.punctuation
    for char in '[]{}()\'"':
        allowed_chars = allowed_chars.replace(char, '')

    # Use secrets.choice for secure random selection
    password = ''.join(secrets.choice(allowed_chars) for _ in range(length))
    return password

def generate_random_email():
    domains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com"]
    username = ''.join(random.choice(string.ascii_letters) for _ in range(8))
    domain = random.choice(domains)
    email = f"{username}@{domain}"
    return email

for i in range(100):
    file.write(f'INSERT INTO users(name,password,email) VALUES("{generate_random_username()}","{generate_random_password()}","{generate_random_email()}");\n') 

file.write("\n")

# admin

for i in range(1,5):
    file.write(f'INSERT INTO admin VALUES({i});\n')

file.write("\n")

# authenticated

street_names = [
    'Rua da Praia',
    'Avenida dos Descobrimentos',
    'Rua de São João',
    'Largo da Sé',
    'Praça do Comércio',
    'Avenida da Liberdade',
    'Rua Direita',
    'Rua dos Anjos',
    'Travessa das Flores',
    'Praça do Rossio',
    'Rua da Boavista',
    'Rua de Santa Catarina',
    'Rua do Carmo',
    'Avenida Dom João II',
    'Largo da Misericórdia',
    'Rua da Esperança',
    'Avenida Marginal',
    'Rua de Santo António',
    'Praça da República',
    'Rua da Bica',
    'Rua das Portas',
    'Avenida da Estação',
    'Rua do Sol',
    'Praça dos Heróis',
    'Rua do Ouro',
    'Avenida dos Aliados',
    'Largo das Oliveiras',
    'Rua da Lapa',
    'Rua dos Mercadores',
    'Praça de Camões',
    'Rua das Glicínias',
    'Avenida da Boa Esperança',
    'Rua da Liberdade',
    'Largo do Pelourinho',
    'Rua do Castelo',
    'Rua do Poço',
    'Avenida da Marina',
    'Rua da Aldeia',
    'Praça do Marquês',
    'Rua dos Namorados',
    'Rua do Moinho',
    'Avenida das Palmeiras',
    'Rua da Cidade',
    'Largo do Mercado',
    'Rua das Estrelas',
    'Praça do Infante',
    'Rua dos Navegadores',
    'Rua dos Pescadores',
    'Avenida do Atlântico',
    'Rua do Cabo',
    'Rua do Porto',
    'Largo da Fonte',
    'Avenida das Acácias',
    'Rua das Gaivotas',
    'Praça da Sé',
    'Rua dos Pássaros',
    'Rua da Ribeira',
    'Rua da Glória',
    'Avenida da Praia',
    'Rua dos Pinheiros',
    'Largo do Chafariz',
    'Rua das Rosas',
    'Rua da Escola',
    'Praça da Flores',
    'Rua dos Cedros',
    'Avenida dos Plátanos',
    'Rua da Montanha',
    'Rua dos Girassóis',
    'Rua da Cova',
    'Praça das Oliveiras',
    'Rua do Riacho',
    'Avenida das Dunas',
    'Rua do Vale',
    'Largo dos Castanheiros',
    'Rua da Fonte',
    'Rua dos Louros',
    'Avenida das Violetas',
    'Rua do Bosque',
    'Rua da Alameda',
    'Praça dos Jacarandás',
    'Rua das Árvores',
    'Rua da Encosta',
    'Rua dos Jardins',
    'Avenida dos Ciprestes',
    'Rua da Serra',
    'Largo das Palmas',
    'Rua das Orquídeas',
    'Rua do Laranjal',
    'Avenida das Tulipas',
    'Rua da Quinta',
    'Rua das Figueiras',
    'Praça da Alegria',
    'Rua dos Castanheiros',
    'Rua das Hortênsias',
    'Rua da Carvalheira',
    'Avenida das Magnólias',
    'Rua das Margaridas',
    'Rua dos Choupos',
    'Largo das Azáleas',
    'Praça das Begónias',
    'Rua dos Cravos',
    'Rua da Amendoeira',
    'Avenida das Camélias',
    'Rua das Giestas',
    'Rua da Madressilva',
    'Rua dos Sabugueiros',
    'Rua da Papoila',
    'Praça das Papoilas',
    'Rua das Violetas',
    'Avenida das Margaridas',
    'Rua das Amarílis',
    'Rua dos Lilases',
    'Largo dos Narcisos',
    'Rua das Papoilas',
    'Rua da Alfazema',
    'Rua dos Crisântemos',
    'Avenida das Orquídeas',
    'Rua dos Narcisos',
    'Rua das Túlipas',
    'Praça das Camélias',
    'Rua dos Lírios',
    'Rua das Azáleas',
    'Rua dos Gerânios',
    'Rua das Hortênsias',
    'Rua dos Pinheiros',
    'Avenida dos Jardins',
    'Rua das Oliveiras',
    'Praça das Acácias',
    'Rua das Magnólias',
    'Rua da Glicínia',
    'Avenida dos Jacarandás',
    'Rua dos Cravos',
    'Rua dos Girassóis',
    'Rua dos Miosótis',
    'Rua da Madressilva',
    'Largo da Camélia',
    'Rua das Begónias',
    'Rua da Amendoeira',
    'Rua da Alegria',
    'Avenida das Flores',
    'Rua da Saudade',
    'Rua dos Choupos',
    'Rua da Solidão',
    'Rua das Margaridas',
    'Praça dos Amores',
    'Rua das Rosas',
    'Rua das Laranjeiras',
    'Avenida da Felicidade',
    'Rua do Bem-estar',
    'Rua da Tranquilidade',
    'Rua da Esperança',
    'Rua do Progresso',
    'Rua da Liberdade',
    'Avenida da Paz',
    'Rua da Igualdade',
    'Praça da Justiça',
    'Rua dos Direitos Humanos',
    'Rua da Fraternidade',
    'Rua da União',
    'Rua da Solidariedade',
    'Avenida da Democracia',
    'Rua da Cidadania',
    'Rua da Tolerância',
    'Rua da Amizade',
    'Praça da Diversidade',
    'Rua da Harmonia',
    'Rua da Cooperação',
    'Avenida da Sustentabilidade',
    'Rua da Ecologia',
    'Rua da Inovação',
    'Rua da Tecnologia',
    'Praça da Cultura',
    'Rua das Artes',
    'Rua da Música'
]

cities = [
    'Vila Nova de Gaia',
    'Amadora',
    'Setúbal',
    'Almada',
    'Odivelas',
    'Matosinhos',
    'Gondomar',
    'Santa Maria da Feira',
    'Oeiras',
    'Vila Franca de Xira',
    'Maia',
    'Barreiro',
    'Castelo Branco',
    'Covilhã',
    'Fafe',
    'Tomar',
    'Portimão',
    'Caldas da Rainha',
    'Penafiel',
    'Vila Real',
    'Bragança',
    'Chaves',
    'Amarante',
    'Lamego',
    'Póvoa de Varzim',
    'Esposende',
    'Trofa',
    'Ponte de Lima',
    'Paredes',
    'Santo Tirso',
    'Valongo',
    'Vila do Conde',
    'Beira-Mar',
    'Estoril',
    'Rio Maior',
    'Castelo de Vide',
    'Elvas',
    'Sesimbra',
    'Loulé',
    'Lagos',
    'Tavira',
    'Vila Real de Santo António',
    'Loures',
    'Loulé',
    'Figueira da Foz',
    'Águeda',
    'Esmoriz',
    'São João da Madeira',
    'Albufeira'
]

districts = [
    'Aveiro',
    'Beja',
    'Braga',
    'Bragança',
    'Castelo Branco',
    'Coimbra',
    'Évora',
    'Faro',
    'Guarda',
    'Leiria',
    'Lisboa',
    'Portalegre',
    'Porto',
    'Santarém',
    'Setúbal',
    'Viana do Castelo',
    'Vila Real',
    'Viseu'
]


def generate_random_address():
    street = random.choice(street_names)
    city = random.choice(cities)
    state = random.choice(districts)
    address = f"{state}, {city}, {street}, {random.randint(1, 9999)}-{random.randint(100,999)}"
    return address

for i in range(5,100):
    file.write(f'INSERT INTO authenticated(user_id,address,isBlocked) VALUES({i},"{generate_random_address()}","{random.choice(["TRUE","FALSE"])}");\n')

file.write("\n")

# wallet

for i in range(5,100):
    file.write(f'INSERT INTO wallet(user_id,money,currency_type) VALUES({i},{random.randrange(0,10000)},"{random.choice(currency_types)}");\n')

file.write("\n")

# unblock appeal


random_words = [
    'Apple',
    'Bicycle',
    'Elephant',
    'Sunshine',
    'Rainbow',
    'Whisper',
    'Mountain',
    'Ocean',
    'Telescope',
    'Piano',
    'Adventure',
    'Galaxy',
    'Chocolate',
    'Serenade',
    'Firefly',
    'Enchantment',
    'Dream',
    'Bamboo',
    'Moonlight',
    'Euphoria',
    'Harmony',
    'Treasure',
    'Carnival',
    'Butterfly',
    'Echo',
    'Lighthouse',
    'Velvet',
    'Potion',
    'Dragon',
    'Velvet',
    'Carousel',
    'Symphony',
    'Castle',
    'Horizon',
    'Secret',
    'Mystery',
    'Starlight',
    'Serendipity',
    'Twilight',
    'Mirage',
    'Zephyr',
    'Trampoline',
    'Saffron',
    'Whimsical',
    'Aurora',
    'Quicksilver',
    'Opulent',
    'Cascade',
    'Radiance',
    'Tranquility',
    'Running',
    'Jumping',
    'Swimming',
    'Dancing',
    'Reading',
    'Writing',
    'Singing',
    'Eating',
    'Sleeping',
    'Thinking'
]

def generate_random_unblock_title():
    return " ".join(random.choice(random_words) for _ in range(5))

def generate_random__unblock_description():
    return " ".join(random.choice(random_words) for _ in range(20))


for i in range(5,100):
    file.write(f'INSERT INTO unblock_appeal(user_id,title,description) VALUES({i},"{generate_random_unblock_title()}","{generate_random__unblock_description()}");\n')

file.write("\n")

# authenticated_notification

for i in range(100):
    file.write(f'INSERT INTO authenticated_notification(user_id,notification_type) VALUES({random.randint(5,100)},"{random.choice(notification_types)}");\n')

file.write("\n")

# product

languages = [
    'Chinese',
    'Spanish',
    'English',
    'Hindi',
    'Arabic',
    'Bengali',
    'Portuguese',
    'Russian',
    'Japanese',
    'Punjabi',
    'German',
    'Javanese',
    'Telugu',
    'Marathi',
    'Vietnamese',
    'Tamil',
    'French',
    'Urdu',
    'Turkish'
]

for i in range(500):
    name = " ".join(random.choice(random_words) for _ in range(3))
    synopsis = " ".join(random.choice(random_words) for _ in range(40))
    price = random.randint(1,100)
    discount = price - price * random.choice([0,0.1,0.2,0.25,0.5,0.6,0.75,0.8])
    stock = random.randint(1,10000)
    author = generate_random_username()
    editor = generate_random_username()
    language = random.choice(languages)
    file.write(f'INSERT INTO product(name,synopsis,price,discount,stock,author,editor,language) VALUES("{name}","{synopsis}",{price},{discount},{stock},"{author}","{editor}","{language}");\n')

file.write("\n")

# shopping cart

for i in range(5,101):
    file.write(f'INSERT INTO shopping_cart(user_id, product_id) VALUES({i},{random.randint(1,499)});\n')

file.write("\n")

# wishlist

for i in range(5,101):
    file.write(f'INSERT INTO wishlist(user_id, product_id) VALUES({i},{random.randint(1,499)});\n')

# purchase

def generate_random_timestamp():
    start_date = datetime(2000, 1, 1)
    end_date = datetime(2023, 12, 31)
    time_difference = end_date - start_date
    random_seconds = random.randint(0, time_difference.total_seconds())
    random_timestamp = start_date + timedelta(seconds=random_seconds)
    return random_timestamp.strftime("%Y-%m-%d %H:%M:%S")

for i in range(200):
    user_id = random.randint(5,100)
    price = random.randint(1,100)
    quantity = random.randint(1,50)
    payment = random.choice(payment_types)
    destination = generate_random_address()
    state = random.choice(stages)
    orderedAt = generate_random_timestamp()
    orderArrivedAt = generate_random_timestamp()
    while(orderArrivedAt < orderedAt):
        orderArrivedAt = generate_random_timestamp()
    file.write(f'INSERT INTO purchase(user_id, price,quantity,payment_type,destination,stage_state,orderedAt,orderArrivedAt) VALUES({user_id},{price},{quantity},"{payment}","{destination}","{state}",{orderedAt},{orderArrivedAt});\n')

# purchase product

for i in range(300):
    purchase_id = random.randint(1,199)
    product_id = random.randint(1,499)
    quantity = random.randint(1,50)
    price = random.randint(1,200)
    file.write(f'INSERT INTO purchase_product(purchase_id,product_id,quantity,price) VALUES({purchase_id},{product_id},{quantity},{price});\n')

#product statistic

for i in range(500):
    for statistic_type in statistic_types:
        file.write(f'INSERT INTO product_statistic(product_id,statistic_type,result) VALUES({i},"{statistic_type}",{random.randint(0,4567)});\n')

#product category

for i in range(500):
    file.write(f'INSERT INTO product_category(product_id,category_type) VALUES({i},"{random.choice(categories)}");\n')

# review

for i in range(200):
    user_id = random.randint(5,100)
    product_id = random.randint(1,499)
    title = generate_random_unblock_title()
    description = generate_random__unblock_description()
    rating = random.randint(1,5)
    date = generate_random_timestamp()
    file.write(f'INSERT INTO review(user_id,product_id,title,description,rating,date) VALUES({user_id},{product_id},"{title}","{description}",{rating},{date});\n')

# review report

for i in range(20):
    file.write(f'INSERT INTO review_report(review_id,motive,date) VALUES({random.randint(1,199)},"{generate_random__unblock_description()},{generate_random_timestamp()}");\n')


file.close()

end_time = time.time()

execution_time = end_time - start_time

print(f"Execution time: {execution_time:.2f} seconds")