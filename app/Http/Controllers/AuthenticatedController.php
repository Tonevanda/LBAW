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
            'products' => $user->shoppingCart()->get()
            #'Products' => Authenticated::findOrFail($user->user_id)->shoppingCart()
        ]);
    }
    //Show Profile
    public function show(Authenticated $user){
        return view('profile', [
            'user' => $user
        ]);
    }
    public function store(Authenticated $user){
        $data = request()->validate([
            'product_id' => 'required'
        ]);
        $user->shoppingCart()->attach($data['product_id']);
        return redirect()->route('shopping-cart', $user->user_id);

    }
}



//FAZER O PROFILE QUANDO VOLTAR!!