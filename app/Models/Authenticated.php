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
        'address',
        'isBlocked',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function purchases()
    {
        return $this->hasMany(Purchase::class, 'user_id');
    }

    

    public function shoppingCart()
    {
        return $this->belongsToMany(Product::class, 'shopping_cart', 'user_id', 'product_id')
                    ->withPivot('id');
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
