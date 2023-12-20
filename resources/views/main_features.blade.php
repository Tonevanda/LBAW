@extends('layouts.app')

@section('content')
<div class = "about_us">
<h1>Main Features</h1>
<p> Welcome to Bibliophile's Bliss, a literary haven where diverse stories from cultures around the world come together. </p>
<p> The following are the main features you can find on Bibliophile's Bliss:</p>
<div class="details_box">
<ul>
    <li> A diverse library of books while emphasizing convenience for readers.</li> 
    <li> Enhanced search functionality for efficient book discovery.</li>
    <li> Encouraged interactions among readers, authors, and publishers through facilitated reviews. </li>
    <li> Purchase history feature to keep track of your past book purchases.</li>
</ul>
</div>
<p> It's not just a bookshop; every click is an invitation to a new adventure. </p>
<p><a class = "button" href="{{ url('/') }}">Shop Now</a></p>
<p class = "reach_out">Get to know us better - visit our <a class = "blue" href="{{ route('contact_us') }}">About us </a> page.</p>
</div>
@endsection