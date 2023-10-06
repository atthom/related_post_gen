using JSON3
using StructTypes
using DataStructures

struct PostData
    _id::String
    title::String
    tags::Vector{String}
end

struct RelatedPost
    _id::String
    tags::Vector{String}
    related::Vector{PostData}
end

StructTypes.StructType(::Type{PostData}) = StructTypes.Struct()
StructTypes.StructType(::Type{RelatedPost}) = StructTypes.Struct()


function relatedIO()
    json_string = read("../posts.json", String)
    posts = JSON3.read(json_string, Vector{PostData})

    @time "Without I/O" begin
        all_related_posts = related(posts)
    end

    open("../related_posts_julia_v3.json", "w") do f
        JSON3.write(f, all_related_posts)
    end
end

@views function related(posts)
    post_tags = [p.tags for p in posts]
    tag_map = Dict{String, Vector{Int16}}()
    for (idx, post_tags) in enumerate(post_tags)
        for tag in post_tags
            if !haskey(tag_map, tag)
                tag_map[tag] = Vector{Int16}()
            end
            push!(tag_map[tag], idx)
        end
    end

    l_post = length(posts)
    all_related_posts = Vector{RelatedPost}()
    tagged_post_count = Array{Int16}(undef, l_post)

    for (i_post, post) in enumerate(posts)
        tagged_post_count[:] .= 0

        for t1 in post.tags, p_idx in tag_map[t1]
            if p_idx != i_post
                tagged_post_count[p_idx] += 1
            end
        end

        h = MutableBinaryHeap(Base.By(last), Vector{Tuple{UInt16, UInt16}}())

        for (id_count, pcount) in enumerate(tagged_post_count)
            if length(h) < 5
                push!(h, (id_count, pcount))
            elseif first(h)[2] < pcount
                pop!(h)
                push!(h, (id_count, pcount))
            end
        end

        all_extract = [pid for (pid, pcount) in extract_all_rev!(h)]
        push!(all_related_posts, RelatedPost(post._id, post.tags, posts[all_extract]))
    end

    return all_related_posts
end


#json_string = read("../posts.json", String) # 180ms
#posts = JSON3.read(json_string, Vector{PostData}) # 3.3ms

relatedIO()


