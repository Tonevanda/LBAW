<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Product;
use Illuminate\Auth\Access\AuthorizationException;

class ProductPolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }


    public function addToCart(User $user, Product $product): bool
    {
        if($product->stock <= 0){
            throw new AuthorizationException("Can't add a book with 0 stock to a shopping cart");
        }
        if($user->isAdmin()){
            throw new AuthorizationException("Can't add a book to shopping cart if you are an Admin");
        }
        if($user->authenticated()->first()->shoppingCart()->where('product_id', $product->id)->count() > $product->stock){
            throw new AuthorizationException("Your shopping cart will exceed this book's stock");
        }
        return true;
    }

    public function removeFromCart(User $user): bool
    {
        if($user->isAdmin()){
            throw new AuthorizationException("Admins cant remove a book from the shopping cart");
        }
        return true;
    }
}
