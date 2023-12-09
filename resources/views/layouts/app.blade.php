<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <!-- CSRF Token -->
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ config('app.name', 'Laravel') }}</title>

        <!-- Styles -->
        <link href="{{ url('css/milligram.min.css') }}" rel="stylesheet">
        <link href="{{ url('css/app.css') }}" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css">
        <script type="text/javascript">
            // Fix for Firefox autofocus CSS bug
            // See: http://stackoverflow.com/questions/18943276/html-5-autofocus-messes-up-css-loading/18945951#18945951
        </script>
        <script type="text/javascript" src={{ url('js/app.js') }} defer>
        </script>

    </head>
    <body>
        <main>
            <header>
                <h1><a href="{{ url('/') }}">Bibliophile's Bliss</a></h1>
                <div class="header-buttons">
                @if (Auth::check())
                    @if (Auth::user()->isAdmin())
                        <a class="button" href="{{ route('users')}}">Users</a>
                        <a class="button" href="{{ route('create_user')}}">Create User</a>
                        <a class="button" href="{{ route('add_products')}}">Add Products</a>
                        <a class="button" href="{{ route('logout') }}"> Logout </a> 
                    @else
                        <p class="wallet"> {{Auth::user()->authenticated()->first()->wallet()->first()->money}} </p>
                        <i class="fas fa-dollar-sign"></i>
                        <a class="buttonss" href="{{ route('shopping-cart',Auth::user()->id) }}">
                            <i class="fas fa-shopping-cart"></i> Shopping Cart
                        </a>  
                        <a class="buttonss" href="{{ route('wishlist',Auth::user()->id) }}">
                            <i class="fas fa-heart"></i> Wishlist
                        </a>  
                        <div class="user-button" onclick="toggleMenu()">
                            <i class="fas fa-user"></i> 
                        </div>
                        <div class="mini-menu" id="miniMenu">
                            <ul>
                            <li><a class="menu-button" href="{{ route('profile',Auth::user()->id)}}">Profile</a></li>
                            <li><a class="menu-button" href="{{ route('purchase_history',Auth::user()->id) }}"> Purchase History </a></li>
                            <li><a class="menu-button" href="{{ route('logout') }}"> Logout </a></li>
                            </ul>
                        </div>                        
                    @endif
                @else 
                    <a class="button button-outline" href="{{ route('login') }}">Login</a>
                    <a class="button button-outline" href="{{ route('register') }}">Register</a>
                @endif
                </div>
            </header>
                <div id="content">
                @yield('content')
                </div>
        </main>
        <footer>
            <p><a href="{{ route('about_us')}}">About us</a></p>
            <p><a href="{{ route('contact_us') }}">Contact us</a></p>
            <p>&copy; 2023 Bibliophile's Bliss. All rights reserved.</p>
        </footer>
    </body>
</html>