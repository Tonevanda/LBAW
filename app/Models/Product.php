<?php

namespace App\Models;

use App\Models\Purchase;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Product extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'synopsis', 'price', 'stock', 'author', 'editor', 'language', 'image'];

    protected $table = 'product';

    public $timestamps = false;

    protected $primaryKey = 'id';

    public function buyers()
    {
        return $this->belongsToMany(Authenticated::class, 'shopping_cart', 'product_id', 'user_id');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'product_id');
    }
    
    public function purchases()
    {
        return $this->belongsToMany(Purchase::class, 'purchase_product', 'product_id', 'purchase_id');
    }

    public function wishlists()
    {
        return $this->belongsToMany(Authenticated::class, 'wishlist', 'product_id', 'user_id')->withPivot('id');
    }

    public function scopeFilter($query, array $filters, $category_filter, $search_filter, $name_filter)
    {  
        return $query->leftJoin('product_category', 'product_category.product_id', '=', 'product.id')
            ->whereRaw($category_filter, [$filters['category']])
            ->where('price', '<=', $filters['price'])
            ->whereRaw($search_filter, [$name_filter])
            ->orderByRaw('ts_rank(tsvectors, to_tsquery(\'english\', ?)) DESC', [$name_filter]);
    }

    public function productStatistic()
    {
        return $this->hasMany(ProductStatistic::class, 'product_id');
    }

    public function purchaseProducts()
    {
        return $this->hasMany(PurchaseProduct::class, 'product_id');
    }

    public function scopeFilterVectors($query, $name_filter)
    {
        return $query->whereRaw('tsvectors @@ to_tsquery(\'english\', ?)', [$name_filter])
                      ->orderByRaw('ts_rank(tsvectors, to_tsquery(\'english\', ?)) DESC', [$name_filter]);
    }

    
}
