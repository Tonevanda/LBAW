<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Product;

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
        return $product->stock > 0 && !$user->isAdmin() && $user->authenticated()->first()->shoppingCart()->where('product_id', $product->id)->count() < $product->stock;
    }

    public function removeFromCart(User $user, Product $product): bool
    {
        return $product->stock > 0 && !$user->isAdmin() && $user->authenticated()->first()->shoppingCart()->where('product_id', $product->id)->count() < $product->stock;
    }
}
