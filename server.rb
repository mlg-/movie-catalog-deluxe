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

  order = params['order']
  where = ""
  if order == nil || order == "title"
    order = "title"
    sort = "ASC"
  elsif order == "rating"
    sort = "DESC"
    where = "WHERE rating IS NOT NULL"
  else
    sort = "DESC"
  end

  page = params['page']
  if page == nil
    offset = 0
  else
    offset = (page.to_i - 1) * 20
  end

  sql= "SELECT movies.title, movies.id, movies.year, movies.rating,
         genres.name AS genre, studios.name AS studio_name
        FROM movies
        LEFT JOIN genres ON movies.genre_id = genres.id
        RIGHT JOIN studios ON movies.studio_id = studios.id
        #{where}
        ORDER BY movies.#{order} #{sort}
        LIMIT 20
        OFFSET #{offset}"
  movies_table = db_connection{ |conn| conn.exec(sql)}
  movies = movies_table.to_a

  erb :'/movies/index', locals: { movies: movies, page: page, order: order }
end

get '/movies/:id' do
  sql= "SELECT movies.title AS movie_title,
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
  WHERE movies.id = #{params['id']}
  ORDER BY cast_members.character"
  movie_table = db_connection{ |conn| conn.exec(sql)};
  movie = movie_table.to_a
  erb :'/movies/show', locals: { movie: movie, id: params[:id] }
end

get '/actors' do
  page = params['page']
    if page == nil
      offset = 0
    else
      offset = (page.to_i - 1) * 20
    end

  sql = "SELECT actors.id, actors.name
  FROM actors
  ORDER BY name
  LIMIT 20
  OFFSET #{offset}"
  actors_table = db_connection{ |conn| conn.exec(sql)}
    actors = actors_table.to_a
  erb :'actors/index', locals: { actors: actors, page: page }
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
