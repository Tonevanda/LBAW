<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $table = 'wallet';

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'money',
        'currency_type'
    ];

    public function user()
    {
        return $this->belongsTo(Authenticated::class, 'user_id');
    }

    public function currency()
    {
        return $this->has(Currency::class, 'currency_type');
    }


    public function scopeFilter($query, $user_id)
    {
        $query->where('user_id', '=', $user_id);
    }

}
