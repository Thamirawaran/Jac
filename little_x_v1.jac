import:py from fastapi {FastAPI, HTTPException}
import:py torch;
import:py from sklearn.metrics.pairwise {cosine_similarity}
import:py numpy as np;
import:py random;

node User{
    has user_name:str;
}

node Post{
    has content:str;
}

edge Posting{}

edge Following{}

edge Reply{}

edge React{
    has reaction:str;
}

walker create_user{
    has user_name:str;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["user_name"];
    }

    can create with `root entry{
        root ++> (new_user:= User(self.user_name));
        report new_user;
    }
}

walker follow_request{
    has follower_jid:str;
    has followee_jid:str;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["follower_jid", "followee_jid"];
    }

    can follow with `root entry{
        follower = &(self.follower_jid);
        followee = &(self.followee_jid);
        follower +:Following():+> followee;
        report f"{follower.user_name} is now following {followee.user_name}";
    }
}

walker tweet{
    has poster_jid:str;
    has content:str;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["poster_jid","content"];
    }

    can tweet with `root entry{
        (poster := &(self.poster_jid)) +:Posting():+> (post := Post(self.content));
        report f"{poster.user_name} is posting content: {post.content}";
        report post;
    }
}

walker comment{
    has post_jid:str;
    has poster_jid:str;
    has content:str;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["post_jid","poster_jid","content"];
    }

    can comment with `root entry{
        (poster := &(self.poster_jid)) +:Posting():+> (post := Post(self.content));
        &(self.post_jid) +:Reply():+> post;
        report f"{poster.user_name} is posting comment: {post.content} on tweet {(&(self.post_jid)).content}";
        report post;
    }
}

walker react{
    has post_jid:str;
    has reactor_jid:str;
    has reaction:str;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["post_jid","reactor_jid","reaction"];
    }

    can react with `root entry{
        (reactor:= &(self.reactor_jid)) +:React(self.reaction):+> &(self.post_jid);
        report f"{reactor.user_name} is posting reacting {self.reaction} on tweet {(&(self.post_jid)).content}";
    }
}

walker search{
    has query:Post;
    has tweets:list;

    # TODO : It will be removed eventually
    obj __specs__{
        static has auth: bool = False, as_query: list = ["query","tweets"];
    }

    can search with `root entry{
        tweet_array = np.vstack(tweets);
        similarity = cosine_similarity(self.query, tweet_array).flatten();
        ranked_tweets = sorted(zip(tweets, similarity), key=(with x:int can x), reverse=True);

        top_tweets = [{"content": tweet.content, "similarity": sim} for (tweet, sim) in ranked_tweets[:5]];
        report top_tweets;
    }
}
