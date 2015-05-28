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
  erb :'/movies/show'
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
    "SELECT movies.title, cast_members.character, movies.id
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
