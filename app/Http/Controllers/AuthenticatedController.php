<?php

namespace App\Http\Controllers;

use App\Models\Authenticated;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AuthenticatedController extends Controller
{
    //Show all products in the shopping cart
    public function index(Authenticated $user){
        return view('shopping_cart', [
            'products' => $user->getAllProducts()
            #'Products' => Authenticated::findOrFail($user->user_id)->getAllProducts()
        ]);
    }
}
