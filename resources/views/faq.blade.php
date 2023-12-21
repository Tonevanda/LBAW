@extends('layouts.app')

@section('content')

<div class = "about_us">
<h1>FAQ</h1>
<p> Welcome to our Frequently Asked Questions page! We're delighted to help you navigate your book-buying journey with us. </p>
<p> This section is designed to provide quick, clear answers to your common queries, from searching for books and placing orders to understanding delivery options and return policies. </p>
<ul>
    <div class = "faq">
    <ul> How do I search for a specific book?
        <li> To find a specific book on our homepage, you can type in the book's title in the search bar. Additionally, you can refine your search by selecting a category. If you have a price point in mind, adjust the price slider to your desired range. Once you've set your criteria, hit the 'SEARCH' button to see the books that fit your search.</li> 
    </ul>
    </div>
    <div class = "faq">
    <ul> What payment methods do you accept?
        <li> For your convenience, we offer multiple payment methods. You can pay using any major credit or debit card, through PayPal, or with our website's wallet option, which allows you to preload funds for future purchases.</li>
    </ul>
    </div>
    <div class = "faq">
    <ul> Is it safe to make payments on your website?
        <li> Yes, making payments on our website is safe. We use secure payment processing systems to ensure your personal and payment information is protected. </li>
    </ul>
    </div>
    <div class = "faq">
    <ul> Can I track my order?
        <li> Yes, you have the option to select order tracking before completing your purchase. This allows you to monitor the delivery status of your order from dispatch to arrival.</li>
    </ul>
    </div>
    <div class = "faq">
    <ul> What is your return policy?
        <li> Our return policy allows you to return your order within two weeks of the arrival date. This gives you ample time to decide if your purchase meets your expectations.</li>
    </ul>
    </div>
    <div class = "faq">
    <ul> Can I cancel or change my order?
        <li> You can cancel your order, but once it's placed, changes to the order are not possible. </li>
    </ul>
    </div>
    <div class = "faq">
    <ul> How can I contact you?
        <li> You can find our contact details on the <a class = "blue" href="{{ route('contact_us') }}">Contact us</a> page of our website,  where you'll find various ways to get in touch, including email and phone.</li>
    </ul>
    </div>
</ul>
<p class = "reach_out">Didn't find the answer you're looking for? Feel free to reach out - <a class = "blue" href="{{ route('contact_us') }}"> Contact us </a></p>
</div>
@endsection