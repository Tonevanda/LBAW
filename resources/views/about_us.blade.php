@extends('layouts.app')

@section('content')

<div class = "about_us">
<h1>About us</h1>
<p> Welcome to Bibliophile's Bliss, a literary haven where diverse stories from cultures around the world come together. </p>
<p> Discover a user-friendly platform with a rich collection, crafted for readers of all ages. </p>
<hr>
<ul><p> Our Main Goals</p>
    <ul> Promote Reading Culture
        <li> Develop a diverse library of books while emphasizing convenience for readers.</li> 
    </ul>
    <ul>Integrate Advanced Search Mechanisms
        <li> Enhance the search functionality for efficient book discovery.</li>
    </ul>
    <ul> Foster Community Building
        <li> Encourage interactions among readers, authors, and publishers through facilitated reviews. </li>
    </ul>
    <ul> Support Small Authors and Publishers 
        <li> Build positive relations with small authors and publishers, providing a supportive platform for their work.</li>
    </ul>
    <ul>Provide Help and Product Information
        <li> Offer comprehensive information about products and services.</li>
    </ul>
</ul>
<hr>
<p> It's not just a bookshop; every click is an invitation to a new adventure. </p>
<p><a class = "button" href="{{ url('/') }}">Shop Now</a></p>
<p class = "reach_out">Require assistance or have inquiries? Feel free to reach out – <a class = "blue" href="{{ route('contact_us') }}">Contact us</a></p>
</div>
@endsection