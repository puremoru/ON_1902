# frozen_string_literal: true
module Api
  module V1
    class QuizesController < ApplicationController
      RAKUTEN_APP_ID = Rails.application.credentials.rakuten[:app_id]
      RAKUTEN_APP_SECRET = Rails.application.credentials.rakuten[:app_secret]

      def new
        keywords = %w[お茶 漫画 ゲーム PC お土産 化粧品 財布 曲 弁当]

        # NOTE: idをつける必要があるのはNUXTの関係
        arrange_keywords = keywords.map.with_index(1) { |k, idx| { id: idx, keyword: k } }
        render json: { keywords: arrange_keywords }
      end

      def create
        render json: { error: 'キーワードがパラメータとして必須です' } unless params[:keyword]

        base_url = 'https://app.rakuten.co.jp/services/api/Product/Search/20170426'
        param = {
          format: 'json',
          keyword: params[:keyword],
          sort: '-seller',
          applicationId: RAKUTEN_APP_ID
        }.to_param
        request_url = base_url + '?' + param

        response = JSON.parse(HTTPClient.get(request_url).body)
        render json: { error: '現在繋がりにくい状態です。もう一度お試しください' } if response['error']

        ranking_data = generate_ranking_data(response)
        quiz = create_quiz_records(ranking_data)
        candidate_answers = ranking_data.map { |data| data[:name] }

        # 1~9位の情報と回答の候補を返す
        render json: { quiz_id: quiz.id, ranking: ranking_data[0..8], candidate_answers: candidate_answers }
      end

      def show
        render json: { status: 'SUCCESS' }
      end


      private

      # TODO: キーワードに関係しないものは除外するようにしたい
      # 水って検索したときに「(水)で流せるおしりふき」というのが出てくる。
      # 水で検索した一番目のgenleldを取得そのgenleldでAND検索をすればより良いものが出てくるのでは？？？
      def generate_ranking_data(response)
        response['Products'].map.with_index(1) { |p, idx| { name: p['Product']['productName'], rank: idx } }
      end

      def create_quiz_records(ranking_data)
        ActiveRecord::Base.transaction do
          quiz = Quiz.create(keyword: params[:keyword])
          ranking_data.each do |info|
            # NOTE: 1~9位のランキングを保存
            quiz.rankings.create(name: info[:name], order: info[:rank]) if [*1..9].include?(info[:rank])

            # NOTE: 回答の候補を保存
            quiz.candidate_answers.create(name: info[:name], order: info[:rank])
          end

          quiz
        end
      end
    end
  end
end