FROM ruby:2.6
RUN gem install bundler:2.1.4
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
