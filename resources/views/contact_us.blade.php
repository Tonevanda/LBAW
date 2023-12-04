@extends('layouts.app')

@section('content')

<div class = "contact_us">
    <h1>Contact us</h1>
    <ul class="contact-list">
        <li>Adress
            <i class="fas fa-map-marker-alt"></i>
            <p>Bliss Street, No. 123, Bibliotopia</p>
        </li>
        <li>Email
            <i class="fas fa-envelope"></i>
            <p>contact@bibliophilesbliss.com</p>
        </li>
        <li>Phone Number
            <i class="fas fa-phone"></i>
            <p>+123 123456789</p>
        </li>
        <li>Website
            <i class="fas fa-globe"></i>
            <p><a class="blue" href="{{ url('/') }}">https://bibliophilesbliss.com</a></p>
        </li>
    </ul>
</div>

@endsection