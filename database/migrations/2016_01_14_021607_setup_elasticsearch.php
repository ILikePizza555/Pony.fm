<?php

/**
 * Pony.fm - A community for pony fan music.
 * Copyright (C) 2016 Peter Deltchev
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;
use Poniverse\Ponyfm\Console\Commands\RebuildSearchIndex;

class SetupElasticsearch extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $elasticsearch = Elasticsearch::connection();

        $elasticsearch->indices()->create([
            'index' => 'ponyfm',
            'body'  => [
                'mappings' => [
                    'track' => [
                        '_source' => ['enabled' => true],
                        'dynamic' => 'strict',
                        'properties' => [
                            'title' => ['type' => 'string'],
                            'artist' => ['type' => 'string'],
                            'published_at' => ['type' => 'date'],
                            'genre' => ['type' => 'string'],
                            'track_type' => ['type' => 'string'],

                            // This field is intended to be used as an array.
                            // Note that all Elasticsearch fields can technically be used as arrays.
                            // See: https://www.elastic.co/guide/en/elasticsearch/reference/current/array.html
                            'show_songs' => ['type' => 'string'],
                        ]
                    ],

                    'album' => [
                        '_source' => ['enabled' => true],
                        'dynamic' => 'strict',
                        'properties' => [
                            'title' => ['type' => 'string'],
                            'artist' => ['type' => 'string'],

                            // This field is intended to be used as an array.
                            // Note that all Elasticsearch fields can technically be used as arrays.
                            // See: https://www.elastic.co/guide/en/elasticsearch/reference/current/array.html
                            'tracks' => ['type' => 'string']
                        ]
                    ]
                ]
            ]
        ]);

        Artisan::call('rebuild:search');
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        $elasticsearch = Elasticsearch::connection();

        $elasticsearch->indices()->delete(['index' => 'ponyfm']);
    }
}
