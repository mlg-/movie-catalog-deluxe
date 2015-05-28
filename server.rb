require 'sinatra'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
    connection.close
  end
end

get '/' do
  erb :index
end

get '/movies' do
  movies_table = db_connection{ |conn| conn.exec(
    "SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio_name
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      RIGHT JOIN studios ON movies.studio_id = studios.id
      ORDER BY title ASC
      LIMIT 10")}
  movies = movies_table.to_a
  erb :'/movies/index', locals: { movies: movies }
end

get '/movies/:id' do
  movie_param_id = [params["id"]]
  movie_table = db_connection{ |conn| conn.exec(
    "SELECT movies.title AS movie_title,
    genres.name AS genre,
    studios.name AS studio,
    cast_members.character AS role,
    actors.name AS actor,
    actors.id AS actor_id
    FROM movies
    JOIN genres ON genres.id = movies.genre_id
    JOIN studios ON studios.id = movies.studio_id
    RIGHT JOIN cast_members ON movies.id = cast_members.movie_id
    RIGHT JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = $1
    ORDER BY cast_members.character
    LIMIT 20", movie_param_id
    )};
  movie = movie_table.to_a
  erb :'/movies/show', locals: { movie: movie, id: params[:id] }
end

get '/actors' do
  actors_table = db_connection{ |conn| conn.exec(
    "SELECT actors.id, actors.name
    FROM actors
    ORDER BY name
    LIMIT 10"
    )}
    actors = actors_table.to_a
  erb :'actors/index', locals: { actors: actors }
end

get '/actors/:id' do
  actor_param_id = [params["id"]]
  actor_table = db_connection{ |conn| conn.exec(
    "SELECT movies.title, cast_members.character, movies.id, actors.name
    FROM movies
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = $1
    ORDER BY title
    LIMIT 20", actor_param_id
    )};
  actor = actor_table.to_a
  erb :'actors/show', locals: { actor: actor, id: params[:id] }
end
