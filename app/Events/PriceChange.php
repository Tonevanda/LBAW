<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PriceChange implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $post_id;


    /**
     * Create a new event instance.
     */
    public function __construct($post_id)
    {
        error_log($post_id);
        $this->post_id = $post_id;
        $this->message = 'item info changed ' . $post_id;

    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    // You should specify the name of the channel created in Pusher.
    public function broadcastOn(): array {
        return ['lbaw'];
    }

    // You should specify the name of the generated notification.
    public function broadcastAs() {
        return 'notification-pricechange';
    }

}
