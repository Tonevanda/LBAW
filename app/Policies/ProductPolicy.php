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


    public function addToCart(User $user, Product $product, $user_id): bool
    {
        if($user->id != $user_id){
            throw new AuthorizationException("This isn't your shopping cart");
        }
        if($product->stock <= 0){
            throw new AuthorizationException("Can't add a book with 0 stock to a shopping cart");
        }
        if($user->isAdmin()){
            throw new AuthorizationException("Can't add a book to shopping cart if you are an Admin");
        }
        if($user->authenticated()->first()->shoppingCart()->where('product_id', $product->id)->count() >= $product->stock){
            throw new AuthorizationException("Your shopping cart will exceed this book's stock");
        }
        return true;
    }

    public function addToWishlist(User $user, Product $product, $user_id): bool
    {
        if($user->id != $user_id){
            throw new AuthorizationException("This isn't your wishlist");
        }
        if($user->isAdmin()){
            throw new AuthorizationException("Can't add a book to shopping cart if you are an Admin");
        }
        if($user->authenticated()->first()->wishlist()->where('product_id', $product->id)->count() == 1){
            throw new AuthorizationException("Your wishlist already contains this book");
        }
        return true;
    }

    public function removeFromCart(User $user, $cart_id): bool
    {
        if($user->isAdmin()){
            throw new AuthorizationException("Admins cant remove a book from the shopping cart");
        }
        $cart_product = $user->authenticated()->first()->shoppingCart()->wherePivot('id', $cart_id);
        if($cart_product->count() == 0){
            throw new AuthorizationException("That product isn't in your shopping cart");
        }

        if($cart_product->first()->pivot->user_id != $user->id){
            throw new AuthorizationException("This isn't your shopping cart");
        }
        return true;
    }

    public function removeFromWishlist(User $user, Product $product): bool
    {
        if($user->isAdmin()){
            throw new AuthorizationException("Admins cant remove a book from the wishlist");
        }
        $wishlist_product = $user->authenticated()->first()->wishlist()->where('product_id', $product->id);
        if($wishlist_product->count() == 0){
            throw new AuthorizationException("Theres no product to be removed from wishlist");
        }
        if($wishlist_product->first()->pivot->user_id != $user->id){
            throw new AuthorizationException("This isn't your wishlist");
        }
        return true;
    }

    public function listCart(User $user, $product_user_id){
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't view the shopping cart");
        }

        if($user->id != $product_user_id){
            throw new AuthorizationException("You are not at your shopping cart");
        }

        return true;
    }

    public function listWishlist(User $user, $product_user_id){
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't view the wishlist");
        }

        if($user->id != $product_user_id){
            throw new AuthorizationException("You are not at your wishlist");
        }

        return true;
    }

    public function create(User $user){
        if(!$user->isAdmin()){
            throw new AuthorizationException("Non admins can't create new products");
        }

        return true;
    }

    public function hasStock(User $user, Product $product, $stock){
        if($product->stock < $stock){
            throw new AuthorizationException("You have products that are out of stock");
        }
        return true;
    }
}
