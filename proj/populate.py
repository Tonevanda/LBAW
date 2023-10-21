import secrets
import string

# Notification 
notification_types = ['payment_notification', 'instock_notification','purchaseinfo_notification','pricechange_notification']
notification_descriptions = [['Your payment has been successful','Your payment has failed, please try again'], 'An item on your wishlist is currently in stock', "Thank you for purchasing at our store, this is your purchase's information:", "An item on your wishlist has had its price changed"]

# Currency
currency_types = ['euro', 'pound','dollar','rupee','yen']

# Payment
payment = ['paypal','credit/debit card','store money']

# Stage
stage = ['payment','order','transportation','delivered']

# Statistc
statistic = ['sales','revenue','AOV','returnrate']

# Category
category = ['fiction','non-fiction','mystery','romance','comics','horror']

# Users
users_name = [

'Olivia',	'Noah'
'Emma',	'Liam'
'Amelia',	'Oliver'
'Sophia',	'Mateo'
'Charlotte',	'Elijah'
'Ava',	'Lucas'
'Isabella',	'Levi'
'Mia',	'Leo'
'Luna',	'Ezra'
'Evelyn',	'Luca'
'Gianna',	'Asher'
'Lily',	'James'
'Aria',	'Ethan'
'Ellie',	'Sebastian'
'Aurora',	'Henry'
'Harper',	'Muhammad'
'Mila',	'Hudson'
'Sofia',	'Maverick'
'Camila',	'Kai'
'Eliana',	'Benjamin'
'Nova',	'Jackson'
'Layla',	'Theo'
'Ella',	'Daniel'
'Hazel',	'Aiden'
'Violet',	'Elias'
'Willow',	'Michael'
'Chloe',	'Mason'
'Ivy',	'Jack'
'Scarlett',	'Grayson'
'Penelope',	'Gabriel'
'Eleanor',	'Josiah'
'Elena',	'Alexander'
'Avery',	'Luke'
'Emily',	'Julian'
'Abigail',	'David'
'Nora',	'Jayden'
'Delilah',	'Carter'
'Maya',	'Logan'
'Isla',	'Theodore'
'Elizabeth',	'Owen'
'Naomi',	'Wyatt'
'Grace',	'Samuel'
'Zoey',	'Ezekiel'
'Riley',	'Waylon'
'Zoe',	'William'
'Emilia',	'Miles'
'Athena',	'Isaiah'
'Paisley',	'Matthew'
'Leilani',	'Santiago'
'Madison',	'Jacob'
]



def generate_random_password(length=12):
    # Define characters to include in the password
    characters = string.ascii_letters + string.digits + string.punctuation

    # Use secrets.choice for secure random selection
    password = ''.join(secrets.choice(characters) for _ in range(length))
    return password












# Abre o ficheiro populate.sql com write perms, elimina o conteúdo que já estiver dentro

file = open('populate.sql',"w")