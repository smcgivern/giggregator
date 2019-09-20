The [Giggregator][giggregator] is a small project to:

1. take a load of Myspace links for bands;
2. find out when those band have gigs;
3. display them all in one place.

It uses Sinatra and Sequel on the backend to accomplish this, along
with HAML and SASS, and supports OpenID as an optional feature to
secure a gig list against someone else editing it.

This used screen-scraping, and I haven't kept this updated so it won't
work with the current Myspace layout. As Myspace isn't really used for
this sort of thing any more, it's more of an historical
artifact. [Ents24] and [Songkick] are similar services.

[giggregator]: http://sean.mcgivern.me.uk/giggregator/
[Ents24]: https://www.ents24.com/
[Songkick]: https://www.songkick.com/
