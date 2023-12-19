<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Authenticated extends Model
{
    use HasFactory;

    protected $table = 'authenticated';

    public $timestamps = false;

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'user_id',
        'name',
        'city',
        'country',
        'phone_number',
        'postal_code',
        'address',
        'isBlocked',
        'payment_method'
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function purchases()
    {
        return $this->hasMany(Purchase::class, 'user_id');
    }

    /*public function getReviewFromProduct($productId)
    {
        return $this->reviews()->where('product_id', $productId)->first();
    }*/
    
    public function shoppingCart()
    {
        return $this->belongsToMany(Product::class, 'shopping_cart', 'user_id', 'product_id')
                    ->withPivot('id');
    }

    public function wishlist()
    {
        return $this->belongsToMany(Product::class, 'wishlist', 'user_id', 'product_id')
                    ->withPivot('id');
    }
    
    public function notifications()
    {
        return $this->hasMany(Notification::class, 'user_id');
    }
    
    public function wallet()
    {
        $wallet = $this->hasOne(Wallet::class, 'user_id')->first();
        $wallet->money = $wallet->money /100;
        $currencySymbols = [
            'euro' => '€',
            'pound' => '£',
            'dollar' => '$',
            'rupee' => '₹',
            'yen' => '¥',
        ];
        $wallet->currencySymbol = $currencySymbols[$wallet->currency_type] ?? '';
        return $wallet;
    }

    public function scopeFilter($query, array $filters)
    {
        if($filters['search'] ?? false){
            $search_filter = $filters['search'];
            $query->leftJoin('users', 'user_id', '=', 'id')
              ->where('email', '=', "$search_filter");
        }
        else
            $query->leftJoin('users', 'user_id', '=', 'id');
    }

}
