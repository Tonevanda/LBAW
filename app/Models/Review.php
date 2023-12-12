<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $table = 'review';

    public $timestamps = false;

    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'user_id',
        'product_id',
        'title',
        'description',
        'rating',
        'date',
    ];

    public function getAuthor()
    {
        return $this->belongsTo(User::class, 'user_id');
    }


    public function products()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function scopeFilter($query, $user_id)
    {
        $query->where('user_id', '=', $user_id);
    }

    /*public function getReviewFromProduct($productId)
    {
        return $this->reviews()->where('product_id', $productId)->first();
    }  */ 
}
