@php
$user = Auth::user();

if($user != NULL && !$user->isAdmin()){
    $auth = $user->authenticated()->first();

    $wallet = $auth->wallet()->first();
    $currency = $wallet->currency()->first();
}

@endphp

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
        <script src="https://js.pusher.com/7.0/pusher.min.js"></script>
        <script type="text/javascript" src={{ url('js/app.js') }} defer>
        </script>

    </head>
    <body>
        <main>
            <header>
                <h1><a href="{{ url('/') }}">Bibliophile's Bliss</a></h1>
                <div class="header-buttons">
                @if (Auth::check())
                    @if ($user->isAdmin())
                    <a class="buttonss" href="{{ route('add_products')}}">
                        <i class="fas fa-plus"></i> <span class="header-text">Add Product</span>
                    </a>  
                    <a class="buttonss" href="{{ route('users') }}">
                        <i class="fas fa-user"></i><span class="header-text"> Users</span>
                    </a>  
                        <a class="button-s" href="{{ route('create_user')}}">Create User</a>
                        <a class="buttonss" href="{{ route('logout') }}">
                            <i class="fa fa-power-off"></i><span class="header-text"> Logout</span>
                        </a> 
                    @else
                    <a title="Wallet" class="buttonss" href="{{ route('wallet',$user->id)}}">
                        <i class="fas fa-wallet"></i><span class="header-text"> {{number_format($wallet->money/100, 2, ',', '.')}}{{$currency->currency_symbol}}</span>
                    </a> 
                    <a class="buttonss" href="{{ route('notifications',$user->id) }}">
                        <i class="fas fa-bell"></i> <span class="header-text">Notifications</span>
                    </a>   
                        <a class="buttonss" href="{{ route('shopping-cart',$user->id) }}">
                            <i class="fas fa-shopping-cart"></i> <span class="header-text">Shopping Cart</span>
                        </a>  
                        <a class="buttonss" href="{{ route('wishlist',$user->id) }}">
                            <i class="fas fa-heart"></i><span class="header-text"> Wishlist</span>
                        </a>  
                        <div class="user-button" title="Menu" onclick="toggleMenu()">
                            <i class="fas fa-user"></i> 
                        </div>
                        <div class="mini-menu" id="miniMenu">
                            <ul>
                            <li><a class="menu-button" href="{{ route('profile',$user->id)}}">Profile</a></li>
                            <li><a class="menu-button" href="{{ route('purchase_history',$user->id) }}"> Purchase History </a></li>
                            <li><a class="menu-button" href="{{ route('account_details',$user->id) }}"> Account Details </a></li>
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
                <div class="content">
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